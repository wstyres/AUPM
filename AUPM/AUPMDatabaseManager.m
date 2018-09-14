#import "AUPMDatabaseManager.h"
#import "NSTask.h"
#import "Repos/AUPMRepoManager.h"
#import "Repos/AUPMRepo.h"
#import "Packages/AUPMPackage.h"
#import "Packages/AUPMPackageManager.h"

@implementation AUPMDatabaseManager

bool packages_file_changed(FILE* f1, FILE* f2);

//Runs apt-get update and cahces all information from apt into a database
- (void)firstLoadPopulation:(void (^)(BOOL success))completion {
  NSLog(@"[AUPM] Performing full database population...");

  //Delete all information in the realm if it exists.
  RLMRealm *realm = [RLMRealm defaultRealm];
  [realm transactionWithBlock:^{
    [realm deleteAllObjects];
  }];

  //Update APT
  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:@"/Applications/AUPM.app/supersling"];
  NSArray *arguments = [[NSArray alloc] initWithObjects: @"apt-get", @"update", @"-o", @"Dir::Etc::SourceList=/var/lib/aupm/aupm.list", @"-o", @"Dir::State::Lists=/var/lib/aupm/lists", @"-o", @"Dir::Etc::SourceParts=/var/lib/aupm/lists/partial/false", nil];
  // apt-get update -o Dir::Etc::SourceList "/etc/apt/sources.list.d/aupm.list" -o Dir::State::Lists "/var/lib/aupm/lists"
  [task setArguments:arguments];

  [task launch];
  [task waitUntilExit];

  dispatch_group_t group = dispatch_group_create();

  AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];
  NSArray *repoArray = [repoManager managedRepoList];
  for (AUPMRepo *repo in repoArray) {
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
      NSDate *methodStart = [NSDate date];
      RLMRealm *realm = [RLMRealm defaultRealm];
      NSArray<AUPMPackage *> *packagesArray = [repoManager packageListForRepo:repo];
      for (AUPMPackage *package in packagesArray) {
        package.repo = repo;
        [repo.packages addObject:package];
      }
      [realm beginWriteTransaction];
      [realm addObject:repo];
      [realm commitWriteTransaction];

      NSDate *methodFinish = [NSDate date];
      NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
      NSLog(@"[AUPM] Time to add %@ to database: %f seconds", [repo repoName], executionTime);
    });
  }

  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

  //Cache installed packages
  [self populateInstalledDatabase:^(BOOL success) {
    completion(true);
  }];
}

- (void)updatePopulation:(void (^)(BOOL success))completion {
  HBLogInfo(@"Performing partial database population...");

  NSTask *cpTask = [[NSTask alloc] init];
  [cpTask setLaunchPath:@"/Applications/AUPM.app/supersling"];
  NSArray *cpArgs = [[NSArray alloc] initWithObjects: @"cp", @"-fR", @"/var/lib/aupm/lists", @"/var/mobile/Library/Caches/com.xtm3x.aupm/", nil];
  [cpTask setArguments:cpArgs];

  [cpTask launch];
  [cpTask waitUntilExit];

  NSTask *refreshTask = [[NSTask alloc] init];
  [refreshTask setLaunchPath:@"/Applications/AUPM.app/supersling"];
  NSArray *refArgs = [[NSArray alloc] initWithObjects: @"apt-get", @"update", nil];
  [refreshTask setArguments:refArgs];

  [refreshTask launch];
  [refreshTask waitUntilExit];

  dispatch_group_t group = dispatch_group_create();

  AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];
  NSArray *bill = [self billOfReposToUpdate];
  for (AUPMRepo *repo in bill) {
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
      NSDate *methodStart = [NSDate date];
      RLMRealm *realm = [RLMRealm defaultRealm];
      NSArray<AUPMPackage *> *packagesArray = [repoManager packageListForRepo:repo];
      for (AUPMPackage *package in packagesArray) {
        package.repo = repo;
        [repo.packages addObject:package];
      }
      [realm beginWriteTransaction];
      [realm addObject:repo];
      [realm commitWriteTransaction];

      NSDate *methodFinish = [NSDate date];
      NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
      NSLog(@"[AUPM] Time to add %@ to database: %f seconds", [repo repoName], executionTime);
    });
  }

  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

  //Cache installed packages
  [self populateInstalledDatabase:^(BOOL success) {
    completion(true);
  }];
}

- (NSArray *)billOfReposToUpdate {
  AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];
  NSArray *repoArray = [repoManager managedRepoList];
  NSMutableArray *bill = [NSMutableArray new];

  for (AUPMRepo *repo in repoArray) {
    BOOL needsUpdate = false;
    NSString *aptPackagesFile = [NSString stringWithFormat:@"/var/lib/aupm/lists/%@_Packages", [repo repoBaseFileName]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:aptPackagesFile]) {
      aptPackagesFile = [NSString stringWithFormat:@"/var/lib/aupm/lists/%@_main_binary-iphoneos-arm_Packages", [repo repoBaseFileName]]; //Do some funky package file with the default repos
    }

    NSString *cachedPackagesFile = [NSString stringWithFormat:@"/var/mobile/Library/Caches/com.xtm3x.aupm/lists/%@_Packages", [repo repoBaseFileName]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachedPackagesFile]) {
      cachedPackagesFile = [NSString stringWithFormat:@"/var/mobile/Library/Caches/com.xtm3x.aupm/lists/%@_main_binary-iphoneos-arm_Packages", [repo repoBaseFileName]]; //Do some funky package file with the default repos
      if (![[NSFileManager defaultManager] fileExistsAtPath:cachedPackagesFile]) {
        HBLogInfo(@"There is no cache file for %@ so it needs an update", [repo repoName]);
        needsUpdate = true; //There isn't a cache for this so we need to parse it
      }
    }

    if (!needsUpdate) {
      FILE *aptFile = fopen([aptPackagesFile UTF8String], "r");
      FILE *cachedFile = fopen([cachedPackagesFile UTF8String], "r");
      needsUpdate = packages_file_changed(aptFile, cachedFile);
    }

    if (needsUpdate) {
      [bill addObject:repo];
    }
  }

  if ([bill count] > 0) {
    HBLogInfo(@"Bill of Repositories that require an update: %@", bill);
  }
  else {
    HBLogInfo(@"No repositories need an update");
  }

  return (NSArray *)bill;
}

- (void)populateInstalledDatabase:(void (^)(BOOL success))completion {
  AUPMPackageManager *packageManager = [[AUPMPackageManager alloc] init];
  NSArray *packagesArray = [packageManager installedPackageList];

  //(name text, packageid text, version text, section text, desc text, url text)
  HBLogInfo(@"Started to parse installed packages");

  for (AUPMPackage *package in packagesArray) {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addOrUpdateObject:package];
    [realm commitWriteTransaction];
  }

  completion(true);
}
//
// - (void)deletePackagesFromRepo:(AUPMRepo *)repo inDatabase:(sqlite3 *)database {
//   sqlite3_exec(database, [[NSString stringWithFormat:@"DELETE FROM packages WHERE repoID = %d", [repo repoIdentifier]] UTF8String], NULL, NULL, NULL);
// }
//
// - (void)deleteRepo:(AUPMRepo *)repo fromDatabase:(sqlite3 *)database {
//   sqlite3_exec(database, [[NSString stringWithFormat:@"DELETE FROM packages WHERE repoID = %d", [repo repoIdentifier]] UTF8String], NULL, NULL, NULL);
//   sqlite3_exec(database, [[NSString stringWithFormat:@"DELETE FROM repos WHERE repoID = %d", [repo repoIdentifier]] UTF8String], NULL, NULL, NULL);
// }
//

@end
