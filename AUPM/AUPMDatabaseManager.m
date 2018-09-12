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

// - (void)updatePopulation:(void (^)(BOOL success))completion {
//   HBLogInfo(@"Performing partial database population...");
//
//   NSTask *cpTask = [[NSTask alloc] init];
//   [cpTask setLaunchPath:@"/Applications/AUPM.app/supersling"];
//   NSArray *cpArgs = [[NSArray alloc] initWithObjects: @"cp", @"-fR", @"/var/lib/apt/lists", @"/var/mobile/Library/Caches/com.xtm3x.aupm/", nil];
//   [cpTask setArguments:cpArgs];
//
//   [cpTask launch];
//   [cpTask waitUntilExit];
//
//   NSTask *refreshTask = [[NSTask alloc] init];
//   [refreshTask setLaunchPath:@"/Applications/AUPM.app/supersling"];
//   NSArray *refArgs = [[NSArray alloc] initWithObjects: @"apt-get", @"update", nil];
//   [refreshTask setArguments:refArgs];
//
//   [refreshTask launch];
//   [refreshTask waitUntilExit];
//
//   dispatch_group_t group = dispatch_group_create();
//
//   NSArray *bill = [self billOfReposToUpdate];
//   for (AUPMRepo *repo in bill) {
//     sqlite3_config(SQLITE_CONFIG_SERIALIZED);
//     static pthread_mutex_t mutex;
//     pthread_mutex_init(&mutex,NULL);
//     dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
//       sqlite3 *sqlite3Database;
//       sqlite3_open([_databasePath UTF8String], &sqlite3Database);
//       sqlite3_stmt *repoStatement;
//
//       //Replace repo information
//       int repoID = [repo repoIdentifier];
//       HBLogInfo(@"Removing information about repo %d (%@)", repoID, [repo repoName]);
//       NSString *repoUpdateQuery = @"UPDATE repos SET repoName = ?, repoBaseFileName = ?, description = ?, repoURL = ?, icon = ? WHERE repoID = ?";
//
//       //Update repo
//       pthread_mutex_lock(&mutex);
//       if (sqlite3_prepare_v2(sqlite3Database, [repoUpdateQuery UTF8String], -1, &repoStatement, nil) == SQLITE_OK) {
//         sqlite3_bind_text(repoStatement, 1, [[repo repoName] UTF8String], -1, SQLITE_TRANSIENT);
//         sqlite3_bind_text(repoStatement, 2, [[repo repoBaseFileName] UTF8String], -1, SQLITE_TRANSIENT);
//         sqlite3_bind_text(repoStatement, 3, [[repo description] UTF8String], -1, SQLITE_TRANSIENT);
//         sqlite3_bind_text(repoStatement, 4, [[repo repoURL] UTF8String], -1, SQLITE_TRANSIENT);
//         sqlite3_bind_blob(repoStatement, 5, (__bridge const void *)[repo icon], -1, SQLITE_TRANSIENT);
//         sqlite3_bind_int(repoStatement, 6, repoID);
//         sqlite3_step(repoStatement);
//       }
//       else {
//         HBLogError(@"%s", sqlite3_errmsg(sqlite3Database));
//       }
//       sqlite3_finalize(repoStatement);
//       pthread_mutex_unlock(&mutex);
//
//       [self deletePackagesFromRepo:repo inDatabase:sqlite3Database];
//
//       AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];
//       NSArray *packagesArray = [repoManager packageListForRepo:repo];
//       NSString *packageQuery = @"insert into packages(repoID, packageName, packageIdentifier, version, section, description, depictionURL) values(?,?,?,?,?,?,?)";
//       sqlite3_stmt *packageStatement;
//       pthread_mutex_lock(&mutex);
//       sqlite3_exec(sqlite3Database, "BEGIN TRANSACTION", NULL, NULL, NULL);
//       if (sqlite3_prepare_v2(sqlite3Database, [packageQuery UTF8String], -1, &packageStatement, nil) == SQLITE_OK) {
//         for (AUPMPackage *package in packagesArray) {
//           //Populate packages database with packages from repo
//           sqlite3_bind_int(packageStatement, 1, repoID);
//           sqlite3_bind_text(packageStatement, 2, [[package packageName] UTF8String], -1, SQLITE_TRANSIENT);
//           sqlite3_bind_text(packageStatement, 3, [[package packageIdentifier] UTF8String], -1, SQLITE_TRANSIENT);
//           sqlite3_bind_text(packageStatement, 4, [[package version] UTF8String], -1, SQLITE_TRANSIENT);
//           sqlite3_bind_text(packageStatement, 5, [[package section] UTF8String], -1, SQLITE_TRANSIENT);
//           sqlite3_bind_text(packageStatement, 6, [[package description] UTF8String], -1, SQLITE_TRANSIENT);
//           sqlite3_bind_text(packageStatement, 7, [[package depictionURL].absoluteString UTF8String], -1, SQLITE_TRANSIENT);
//           sqlite3_step(packageStatement);
//           sqlite3_reset(packageStatement);
//           sqlite3_clear_bindings(packageStatement);
//         }
//       }
//       else {
//         HBLogError(@"%s", sqlite3_errmsg(sqlite3Database));
//       }
//       sqlite3_finalize(packageStatement);
//       sqlite3_exec(sqlite3Database, "COMMIT TRANSACTION", NULL, NULL, NULL);
//       pthread_mutex_unlock(&mutex);
//     });
//   }
//
//   dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
//
//   [self populateInstalledDatabase:^(BOOL success) {
//     completion(true);
//   }];
// }
//
// - (NSArray *)billOfReposToUpdate {
//   AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];
//   NSArray *repoArray = [repoManager managedRepoList];
//   NSMutableArray *bill = [NSMutableArray new];
//
//   for (AUPMRepo *repo in repoArray) {
//     BOOL needsUpdate = false;
//     NSString *aptPackagesFile = [NSString stringWithFormat:@"/var/lib/apt/lists/%@_Packages", [repo repoBaseFileName]];
//     if (![[NSFileManager defaultManager] fileExistsAtPath:aptPackagesFile]) {
//       aptPackagesFile = [NSString stringWithFormat:@"/var/lib/apt/lists/%@_main_binary-iphoneos-arm_Packages", [repo repoBaseFileName]]; //Do some funky package file with the default repos
//     }
//
//     NSString *cachedPackagesFile = [NSString stringWithFormat:@"/var/mobile/Library/Caches/com.xtm3x.aupm/lists/%@_Packages", [repo repoBaseFileName]];
//     if (![[NSFileManager defaultManager] fileExistsAtPath:cachedPackagesFile]) {
//       cachedPackagesFile = [NSString stringWithFormat:@"/var/mobile/Library/Caches/com.xtm3x.aupm/lists/%@_main_binary-iphoneos-arm_Packages", [repo repoBaseFileName]]; //Do some funky package file with the default repos
//       if (![[NSFileManager defaultManager] fileExistsAtPath:cachedPackagesFile]) {
//         HBLogInfo(@"There is no cache file for %@ so it needs an update", [repo repoName]);
//         needsUpdate = true; //There isn't a cache for this so we need to parse it
//       }
//     }
//
//     if (!needsUpdate) {
//       FILE *aptFile = fopen([aptPackagesFile UTF8String], "r");
//       FILE *cachedFile = fopen([cachedPackagesFile UTF8String], "r");
//       needsUpdate = packages_file_changed(aptFile, cachedFile);
//     }
//
//     if (needsUpdate) {
//       [bill addObject:repo];
//     }
//   }
//
//   if ([bill count] > 0) {
//     HBLogInfo(@"Bill of Repositories that require an update: %@", bill);
//   }
//   else {
//     HBLogInfo(@"No repositories need an update");
//   }
//
//   return (NSArray *)bill;
// }
//
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
