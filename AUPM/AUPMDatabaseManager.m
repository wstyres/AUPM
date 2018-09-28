#import "AUPMDatabaseManager.h"
#import "NSTask.h"
#import "Repos/AUPMRepoManager.h"
#import "Repos/AUPMRepo.h"
#import "Packages/AUPMPackage.h"
#import "Packages/AUPMPackageManager.h"
#import "Updates/AUPMDateKeeper.h"
#include "Repos/dpkgver.c"

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

  AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];
  NSArray *repoArray = [repoManager managedRepoList];
  AUPMDateKeeper *dateKeeper = [[AUPMDateKeeper alloc] init];
  dateKeeper.date = [NSDate date];
  [[RLMRealm defaultRealm] transactionWithBlock:^{
    for (AUPMRepo *repo in repoArray) {
      NSDate *methodStart = [NSDate date];
      NSArray<AUPMPackage *> *packagesArray = [repoManager packageListForRepo:repo];
      [realm addObject:repo];
      for (AUPMPackage *package in packagesArray) {
        package.dateKeeper = dateKeeper;
      }

      @try {
        [realm addObjects:packagesArray];
      }
      @catch (NSException *e) {
        NSLog(@"[AUPM] Could not add object to realm: %@", e);
      }

      NSDate *methodFinish = [NSDate date];
      NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
      NSLog(@"[AUPM] Time to add %@ to database: %f seconds", [repo repoName], executionTime);
    }
  }];

  NSDate *newUpdateDate = [NSDate date];
  [[NSUserDefaults standardUserDefaults] setObject:newUpdateDate forKey:@"lastUpdatedDate"];

  [self updateEssentials:^(BOOL success) {
    completion(true);
  }];
}

- (void)updatePopulation:(void (^)(BOOL success))completion {
  HBLogInfo(@"Performing partial database population...");

  NSTask *removeCacheTask = [[NSTask alloc] init];
  [removeCacheTask setLaunchPath:@"/Applications/AUPM.app/supersling"];
  NSArray *rmArgs = [[NSArray alloc] initWithObjects: @"rm", @"-rf", @"/var/mobile/Library/Caches/xyz.willy.aupm/lists", nil];
  [removeCacheTask setArguments:rmArgs];

  [removeCacheTask launch];
  [removeCacheTask waitUntilExit];

  NSTask *cpTask = [[NSTask alloc] init];
  [cpTask setLaunchPath:@"/Applications/AUPM.app/supersling"];
  NSArray *cpArgs = [[NSArray alloc] initWithObjects: @"cp", @"-fR", @"/var/lib/aupm/lists", @"/var/mobile/Library/Caches/xyz.willy.aupm/", nil];
  [cpTask setArguments:cpArgs];

  [cpTask launch];
  [cpTask waitUntilExit];

  NSTask *refreshTask = [[NSTask alloc] init];
  [refreshTask setLaunchPath:@"/Applications/AUPM.app/supersling"];
  NSArray *arguments = [[NSArray alloc] initWithObjects: @"apt-get", @"update", @"-o", @"Dir::Etc::SourceList=/var/lib/aupm/aupm.list", @"-o", @"Dir::State::Lists=/var/lib/aupm/lists", @"-o", @"Dir::Etc::SourceParts=/var/lib/aupm/lists/partial/false", nil];
  [refreshTask setArguments:arguments];

  [refreshTask launch];
  [refreshTask waitUntilExit];

  RLMRealm *realm = [RLMRealm defaultRealm];

  AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];
  NSArray *bill = [self billOfReposToUpdate];
  for (AUPMRepo *repo in bill) {
    NSDate *methodStart = [NSDate date];
    NSArray<AUPMPackage *> *packagesArray = [repoManager packageListForRepo:repo];
    [realm transactionWithBlock:^{
      [realm addOrUpdateObject:repo];
    }];

    [realm beginWriteTransaction];
    @try {
      [realm addOrUpdateObjects:packagesArray];
    }
    @catch (NSException *e) {
      NSLog(@"[AUPM] Could not add object to realm: %@", e);
    }

    [realm commitWriteTransaction];

    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    NSLog(@"[AUPM] Time to add %@ to database: %f seconds", [repo repoName], executionTime);
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

  NSTask *deletePackageCache = [[NSTask alloc] init];
  [deletePackageCache setLaunchPath:@"/Applications/AUPM.app/supersling"];
  NSArray *packageArgs = [[NSArray alloc] initWithObjects: @"rm", @"-rf", @"/var/mobile/Library/Caches/xyz.willy.aupm/lists", nil];
  [deletePackageCache setArguments:packageArgs];

  [deletePackageCache launch];

  //dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
  [[NSUserDefaults standardUserDefaults] setObject:newUpdateDate forKey:@"lastUpdatedDate"];

  [self updateEssentials:^(BOOL success) {
    completion(true);
  }];
}

//Update installed packages and packages that need updates. This needs to be done several times so creating this as a convienence method
- (void)updateEssentials:(void (^)(BOOL success))completion {
  //Repopulate the installed packages, because these change
  [self populateInstalledDatabase:^(BOOL installedSuccess) {
    if (installedSuccess) {
      [self getPackagesThatNeedUpdates:^(NSArray *updates, BOOL hasUpdates) {
        if (hasUpdates) {
          _updateObjects = updates;
          _numberOfPackagesThatNeedUpdates = updates.count;
        }
        _hasPackagesThatNeedUpdates = hasUpdates;
        completion(true);
      }];
    }
  }];
}

//Update packages that are currently installed on the system.
- (void)populateInstalledDatabase:(void (^)(BOOL success))completion {
  AUPMPackageManager *packageManager = [[AUPMPackageManager alloc] init];
  NSArray *packagesArray = [packageManager installedPackageList];

  RLMRealm *realm = [RLMRealm defaultRealm];
  [realm transactionWithBlock:^{
    [realm deleteObjects:[AUPMPackage objectsWhere:@"installed == TRUE"]];
    for (AUPMPackage *package in packagesArray) {
      RLMRealm *realm = [RLMRealm defaultRealm];
      [realm addOrUpdateObject:package];
    }
  }];

  completion(true);
}

- (void)getPackagesThatNeedUpdates:(void (^)(NSArray *updates, BOOL hasUpdates))completion {
  NSMutableArray *updates = [NSMutableArray new];
  RLMResults<AUPMPackage *> *installedPackages = [AUPMPackage objectsWhere:@"installed = true"];

  for (AUPMPackage *package in installedPackages) {
    RLMResults<AUPMPackage *> *otherVersions = [AUPMPackage objectsWhere:@"packageIdentifier == %@", [package packageIdentifier]];
    if ([otherVersions count] != 1) {
      for (AUPMPackage *otherPackage in otherVersions) {
        if (otherPackage != package) {
          int result = verrevcmp([[package version] UTF8String], [[otherPackage version] UTF8String]);

          if (result < 0) {
              [updates addObject:otherPackage];
          }
        }
      }
    }
  }

  NSArray *updateObjects = [self cleanUpDuplicatePackages:updates];
  if (updateObjects.count > 0) {
    completion(updateObjects, true);
  }
  else {
    completion(NULL, false);
  }
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

- (NSArray *)cleanUpDuplicatePackages:(NSArray *)packageList {
    NSMutableDictionary *packageVersionDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *cleanedPackageList = [packageList mutableCopy];

    for (AUPMPackage *package in packageList) {
        if (packageVersionDict[[package packageIdentifier]] == NULL) {
            packageVersionDict[[package packageIdentifier]] = package;
        }

        NSString *arrayVersion = [(AUPMPackage *)packageVersionDict[[package packageIdentifier]] version];
        NSString *packageVersion = [package version];
        int result = verrevcmp([packageVersion UTF8String], [arrayVersion UTF8String]);

        if (result > 0) {
            [cleanedPackageList removeObject:packageVersionDict[[package packageIdentifier]]];
            packageVersionDict[[package packageIdentifier]] = package;
        }
        else if (result < 0) {
            [cleanedPackageList removeObject:package];
        }
    }

    return (NSArray *)cleanedPackageList;
}

- (void)deleteRepo:(AUPMRepo *)repo {
  RLMRealm *realm = [RLMRealm defaultRealm];

  RLMResults<AUPMPackage *> *packagesToDelete = [AUPMPackage objectsWhere:@"repo == %@", repo];

  AUPMRepo *delRepo = [[AUPMRepo objectsWhere:@"repoBaseFileName == %@", [repo repoBaseFileName]] firstObject];

  [realm beginWriteTransaction];
  [realm deleteObjects:packagesToDelete];
  [realm deleteObject:delRepo];
  [realm commitWriteTransaction];

  [self populateInstalledDatabase:^(BOOL success) {
    NSLog(@"[AUPM] Deleted repo");
    //quietly update so the old files get deleted
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/Applications/AUPM.app/supersling"];
    NSArray *arguments = [[NSArray alloc] initWithObjects: @"apt-get", @"update", @"-o", @"Dir::Etc::SourceList=/var/lib/aupm/aupm.list", @"-o", @"Dir::State::Lists=/var/lib/aupm/lists", @"-o", @"Dir::Etc::SourceParts=/var/lib/aupm/lists/partial/false", nil];
    // apt-get update -o Dir::Etc::SourceList "/etc/apt/sources.list.d/aupm.list" -o Dir::State::Lists "/var/lib/aupm/lists"
    [task setArguments:arguments];

    [task launch];
  }];
}

- (BOOL)hasPackagesThatNeedUpdates {
  return _hasPackagesThatNeedUpdates;
}

- (int)numberOfPackagesThatNeedUpdates {
  return _numberOfPackagesThatNeedUpdates;
}

- (NSArray *)updateObjects {
  return _updateObjects;
}

@end
