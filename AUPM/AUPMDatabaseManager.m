#import "AUPMDatabaseManager.h"
#import "NSTask.h"
#import "Repos/AUPMRepoManager.h"
#import "Repos/AUPMRepo.h"
#import "Packages/AUPMPackage.h"
#import "Packages/AUPMPackageManager.h"
#import "Updates/AUPMDateKeeper.h"

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

  //dispatch_group_t group = dispatch_group_create();

  AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];
  NSArray *repoArray = [repoManager managedRepoList];
  AUPMDateKeeper *dateKeeper = [[AUPMDateKeeper alloc] init];
  dateKeeper.date = [NSDate date];
  [[RLMRealm defaultRealm] transactionWithBlock:^{
    for (AUPMRepo *repo in repoArray) {
      //dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        NSDate *methodStart = [NSDate date];
        NSArray<AUPMPackage *> *packagesArray = [repoManager packageListForRepo:repo];
        for (AUPMPackage *package in packagesArray) {
          package.repo = repo;
          package.dateKeeper = dateKeeper;
          [repo.packages addObject:package];
        }

        @try {
          [realm addObject:repo];
        }
        @catch (NSException *e) {
          NSLog(@"[AUPM] Could not add object to realm: %@", e);
        }

        NSDate *methodFinish = [NSDate date];
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
        NSLog(@"[AUPM] Time to add %@ to database: %f seconds", [repo repoName], executionTime);
      //});
    }
  }];

  //dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
  NSDate *newUpdateDate = [NSDate date];
  [[NSUserDefaults standardUserDefaults] setObject:newUpdateDate forKey:@"lastUpdatedDate"];

  //Cache installed packages
  [self populateInstalledDatabase:^(BOOL success) {
    completion(true);
  }];
}

- (void)updatePopulation:(void (^)(BOOL success))completion {
  HBLogInfo(@"Performing partial database population...");

  NSTask *removeCachetask = [[NSTask alloc] init];
  [removeCachetask setLaunchPath:@"/Applications/AUPM.app/supersling"];
  NSArray *rmArgs = [[NSArray alloc] initWithObjects: @"rm", @"-rf", @"/var/mobile/Library/Caches/xyz.willy.aupm/lists", nil];
  [removeCachetask setArguments:rmArgs];

  [removeCachetask launch];
  [removeCachetask waitUntilExit];

  NSTask *cpTask = [[NSTask alloc] init];
  [cpTask setLaunchPath:@"/Applications/AUPM.app/supersling"];
  NSArray *cpArgs = [[NSArray alloc] initWithObjects: @"cp", @"-fR", @"/var/lib/aupm/lists", @"/var/mobile/Library/Caches/xyz.willy.aupm/", nil];
  [cpTask setArguments:cpArgs];

  [cpTask launch];
  [cpTask waitUntilExit];

  //Update APT
  NSTask *refreshTask = [[NSTask alloc] init];
  [refreshTask setLaunchPath:@"/Applications/AUPM.app/supersling"];
  NSArray *arguments = [[NSArray alloc] initWithObjects: @"apt-get", @"update", @"-o", @"Dir::Etc::SourceList=/var/lib/aupm/aupm.list", @"-o", @"Dir::State::Lists=/var/lib/aupm/lists", @"-o", @"Dir::Etc::SourceParts=/var/lib/aupm/lists/partial/false", nil];
  // apt-get update -o Dir::Etc::SourceList "/etc/apt/sources.list.d/aupm.list" -o Dir::State::Lists "/var/lib/aupm/lists"
  [refreshTask setArguments:arguments];

  [refreshTask launch];
  [refreshTask waitUntilExit];

  //dispatch_group_t group = dispatch_group_create();
  RLMRealm *realm = [RLMRealm defaultRealm];

  AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];
  NSArray *bill = [self billOfReposToUpdate];
  for (AUPMRepo *repo in bill) {
    //dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
      NSDate *methodStart = [NSDate date];
      NSArray<AUPMPackage *> *packagesArray = [repoManager packageListForRepo:repo];
      for (AUPMPackage *package in packagesArray) {
        package.repo = repo;
        [repo.packages addObject:package];
      }
      [realm beginWriteTransaction];

      @try {
        [realm addOrUpdateObject:repo];
      }
      @catch (NSException *e) {
        NSLog(@"[AUPM] Could not add %@ to realm: %@", [repo repoName], e);
      }

      [realm commitWriteTransaction];

      NSDate *methodFinish = [NSDate date];
      NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
      NSLog(@"[AUPM] Time to add %@ to database: %f seconds", [repo repoName], executionTime);
    //});
  }

  NSLog(@"[AUPM] Adding times to new packages");
  // //Use this to give new packages new dates, this is pretty bad implementation but it works (probably)
  NSLog(@"[AUPM] Getting list of packages with no date");
  RLMResults *dateless = [AUPMPackage objectsWhere:@"dateKeeper == NULL"];
  NSLog(@"[AUPM] Adding dates to packages");
  NSDate *newUpdateDate = [NSDate date];
  [[RLMRealm defaultRealm] transactionWithBlock:^{
    AUPMDateKeeper *dateKeeper = [[AUPMDateKeeper alloc] init];
    dateKeeper.date = newUpdateDate;
    for (AUPMPackage *package in dateless) {
      package.dateKeeper = dateKeeper;
    }
  }];
  NSLog(@"[AUPM] Done");
  NSLog(@"[AUPM] Populating installed database");

  //dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
  [[NSUserDefaults standardUserDefaults] setObject:newUpdateDate forKey:@"lastUpdatedDate"];

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

    NSString *cachedPackagesFile = [NSString stringWithFormat:@"/var/mobile/Library/Caches/xyz.willy.aupm/lists/%@_Packages", [repo repoBaseFileName]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachedPackagesFile]) {
      cachedPackagesFile = [NSString stringWithFormat:@"/var/mobile/Library/Caches/xyz.willy.aupm/lists/%@_main_binary-iphoneos-arm_Packages", [repo repoBaseFileName]]; //Do some funky package file with the default repos
      if (![[NSFileManager defaultManager] fileExistsAtPath:cachedPackagesFile]) {
        NSLog(@"[AUPM] There is no cache file for %@ so it needs an update", [repo repoName]);
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
    NSLog(@"[AUPM] Bill of Repositories that require an update: %@", bill);
  }
  else {
    NSLog(@"[AUPM] No repositories need an update");
  }

  return (NSArray *)bill;
}

- (void)populateInstalledDatabase:(void (^)(BOOL success))completion {
  AUPMPackageManager *packageManager = [[AUPMPackageManager alloc] init];
  NSArray *packagesArray = [packageManager installedPackageList];

  //(name text, packageid text, version text, section text, desc text, url text)
  HBLogInfo(@"Started to parse installed packages");

  [[RLMRealm defaultRealm] transactionWithBlock:^{
    for (AUPMPackage *package in packagesArray) {
      RLMRealm *realm = [RLMRealm defaultRealm];
      [realm addOrUpdateObject:package];
    }
  }];

  completion(true);
}

- (void)deleteRepo:(AUPMRepo *)repo {
  RLMRealm *realm = [RLMRealm defaultRealm];

  AUPMRepo *delRepo = [[AUPMRepo objectsWhere:@"repoBaseFileName == %@", [repo repoBaseFileName]] firstObject];

  [realm beginWriteTransaction];
  [realm deleteObject:delRepo];
  [realm commitWriteTransaction];
}

@end
