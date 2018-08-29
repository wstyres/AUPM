#import "AUPMDatabaseManager.h"
#import "NSTask.h"
#import "Repos/AUPMRepoManager.h"
#import "Repos/AUPMRepo.h"
#import "Packages/AUPMPackage.h"
#import "Packages/AUPMPackageManager.h"

@interface AUPMDatabaseManager () {
  BOOL *databaseIsOpen;
}
@property (nonatomic, strong) NSString *databasePath;
@property (nonatomic, strong) NSMutableArray *arrResults;

- (void)copyDatabase:(NSString *)database intoDocumentsDirectory:(NSString *)directory;
@end

@implementation AUPMDatabaseManager

bool packages_file_changed(FILE* f1, FILE* f2);

- (id)init {
  self = [super init];
  if (self) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *databaseFilename = @"aupmpackagedb.sql";
    self.databasePath = [documentsDirectory stringByAppendingPathComponent:databaseFilename];
    [self copyDatabase: databaseFilename intoDocumentsDirectory: documentsDirectory];
  }
  return self;
}

//Runs apt-get update and cahces all information from apt into a database
- (void)firstLoadPopulation:(void (^)(BOOL success))completion {
  HBLogInfo(@"Performing full database population...");
  sqlite3 *database;
  AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];

  [self purgeRecords]; //Since this should only be called on the first load, lets nuke the database

  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:@"/Applications/AUPM.app/supersling"];
  NSArray *arguments = [[NSArray alloc] initWithObjects: @"apt-get", @"update", nil];
  [task setArguments:arguments];

  [task launch];
  [task waitUntilExit];

  sqlite3_config(SQLITE_CONFIG_SERIALIZED);
  NSArray *repoArray = [repoManager managedRepoList];
  dispatch_group_t group = dispatch_group_create();
  static pthread_mutex_t mutex;
  pthread_mutex_init(&mutex,NULL);

  sqlite3_open([_databasePath UTF8String], &database);

  //Cache all information from APT
  for (AUPMRepo *repo in repoArray) {
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
      sqlite3_stmt *repoStatement;
      NSString *repoQuery = @"insert into repos(repoName, repoBaseFileName, description, repoURL, icon) values(?,?,?,?,?)";

      //Populate repo database
      NSError *error;
      NSData *iconData = [NSData dataWithContentsOfURL:[repo iconURL] options:NSDataReadingUncached error:&error];
      if (error != nil) {
        HBLogError(@"error while getting icon: %@", error);
      }

      pthread_mutex_lock(&mutex);
      if (sqlite3_prepare_v2(database, [repoQuery UTF8String], -1, &repoStatement, nil) == SQLITE_OK) {
        sqlite3_bind_text(repoStatement, 1, [[repo repoName] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(repoStatement, 2, [[repo repoBaseFileName] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(repoStatement, 3, [[repo description] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(repoStatement, 4, [[repo repoURL] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_blob(repoStatement, 5, [iconData bytes], [iconData length], SQLITE_TRANSIENT);
        sqlite3_step(repoStatement);
      }
      else {
        HBLogError(@"%s", sqlite3_errmsg(database));
      }
      sqlite3_finalize(repoStatement);
      pthread_mutex_unlock(&mutex);

      long long lastRowId = sqlite3_last_insert_rowid(database);

      NSArray *packagesArray = [repoManager packageListForRepo:repo];
      HBLogInfo(@"Started to parse packages for repo %@", [repo repoName]);
      NSString *packageQuery = @"insert into packages(repoID, packageName, packageIdentifier, version, section, description, depictionURL, md5sum) values(?,?,?,?,?,?,?,?)";
      sqlite3_stmt *packageStatement;
      pthread_mutex_lock(&mutex);
      sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, NULL);
      if (sqlite3_prepare_v2(database, [packageQuery UTF8String], -1, &packageStatement, nil) == SQLITE_OK) {
        for (AUPMPackage *package in packagesArray) {
          //Populate packages database with packages from repo
          sqlite3_bind_int(packageStatement, 1, (int)lastRowId);
          sqlite3_bind_text(packageStatement, 2, [[package packageName] UTF8String], -1, SQLITE_TRANSIENT);
          sqlite3_bind_text(packageStatement, 3, [[package packageIdentifier] UTF8String], -1, SQLITE_TRANSIENT);
          sqlite3_bind_text(packageStatement, 4, [[package version] UTF8String], -1, SQLITE_TRANSIENT);
          sqlite3_bind_text(packageStatement, 5, [[package section] UTF8String], -1, SQLITE_TRANSIENT);
          sqlite3_bind_text(packageStatement, 6, [[package description] UTF8String], -1, SQLITE_TRANSIENT);
          sqlite3_bind_text(packageStatement, 7, [[package depictionURL].absoluteString UTF8String], -1, SQLITE_TRANSIENT);
          sqlite3_bind_text(packageStatement, 8, [[package sum] UTF8String], -1, SQLITE_TRANSIENT);
          sqlite3_step(packageStatement);
          sqlite3_reset(packageStatement);
          sqlite3_clear_bindings(packageStatement);
        }
        HBLogInfo(@"Finished packages for repo %@", [repo repoName]);
      }
      else {
        HBLogError(@"%s", sqlite3_errmsg(database));
      }
      sqlite3_finalize(packageStatement);
      sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, NULL);
      pthread_mutex_unlock(&mutex);
    });
  }
  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

  //Cache installed packages
  [self populateInstalledDatabase:^(BOOL success) {
    sqlite3_close(database);
    completion(true);
  }];
}

- (void)updatePopulation:(void (^)(BOOL success))completion {
  HBLogInfo(@"Performing partial database population...");


  NSTask *cpTask = [[NSTask alloc] init];
  [cpTask setLaunchPath:@"/Applications/AUPM.app/supersling"];
  NSArray *cpArgs = [[NSArray alloc] initWithObjects: @"cp", @"-fR", @"/var/lib/apt/lists", @"/var/mobile/Library/Caches/com.xtm3x.aupm/", nil];
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

  NSArray *bill = [self billOfReposToUpdate];
  for (AUPMRepo *repo in bill) {
    sqlite3_config(SQLITE_CONFIG_SERIALIZED);
    static pthread_mutex_t mutex;
    pthread_mutex_init(&mutex,NULL);
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
      sqlite3 *sqlite3Database;
      sqlite3_open([_databasePath UTF8String], &sqlite3Database);
      sqlite3_stmt *repoStatement;

      //Replace repo information
      int repoID = [repo repoIdentifier];
      HBLogInfo(@"Removing information about repo %d (%@)", repoID, [repo repoName]);
      NSString *repoUpdateQuery = @"UPDATE repos SET repoName = ?, repoBaseFileName = ?, description = ?, repoURL = ?, icon = ? WHERE repoID = ?";

      //Update repo
      pthread_mutex_lock(&mutex);
      if (sqlite3_prepare_v2(sqlite3Database, [repoUpdateQuery UTF8String], -1, &repoStatement, nil) == SQLITE_OK) {
        sqlite3_bind_text(repoStatement, 1, [[repo repoName] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(repoStatement, 2, [[repo repoBaseFileName] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(repoStatement, 3, [[repo description] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(repoStatement, 4, [[repo repoURL] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_blob(repoStatement, 5, (__bridge const void *)[repo icon], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(repoStatement, 6, repoID);
        sqlite3_step(repoStatement);
      }
      else {
        HBLogError(@"%s", sqlite3_errmsg(sqlite3Database));
      }
      sqlite3_finalize(repoStatement);
      pthread_mutex_unlock(&mutex);

      [self deletePackagesFromRepo:repo inDatabase:sqlite3Database];

      AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];
      NSArray *packagesArray = [repoManager packageListForRepo:repo];
      NSString *packageQuery = @"insert into packages(repoID, packageName, packageIdentifier, version, section, description, depictionURL) values(?,?,?,?,?,?,?)";
      sqlite3_stmt *packageStatement;
      pthread_mutex_lock(&mutex);
      sqlite3_exec(sqlite3Database, "BEGIN TRANSACTION", NULL, NULL, NULL);
      if (sqlite3_prepare_v2(sqlite3Database, [packageQuery UTF8String], -1, &packageStatement, nil) == SQLITE_OK) {
        for (AUPMPackage *package in packagesArray) {
          //Populate packages database with packages from repo
          sqlite3_bind_int(packageStatement, 1, repoID);
          sqlite3_bind_text(packageStatement, 2, [[package packageName] UTF8String], -1, SQLITE_TRANSIENT);
          sqlite3_bind_text(packageStatement, 3, [[package packageIdentifier] UTF8String], -1, SQLITE_TRANSIENT);
          sqlite3_bind_text(packageStatement, 4, [[package version] UTF8String], -1, SQLITE_TRANSIENT);
          sqlite3_bind_text(packageStatement, 5, [[package section] UTF8String], -1, SQLITE_TRANSIENT);
          sqlite3_bind_text(packageStatement, 6, [[package description] UTF8String], -1, SQLITE_TRANSIENT);
          sqlite3_bind_text(packageStatement, 7, [[package depictionURL].absoluteString UTF8String], -1, SQLITE_TRANSIENT);
          sqlite3_step(packageStatement);
          sqlite3_reset(packageStatement);
          sqlite3_clear_bindings(packageStatement);
        }
      }
      else {
        HBLogError(@"%s", sqlite3_errmsg(sqlite3Database));
      }
      sqlite3_finalize(packageStatement);
      sqlite3_exec(sqlite3Database, "COMMIT TRANSACTION", NULL, NULL, NULL);
      pthread_mutex_unlock(&mutex);
    });
  }

  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

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
    NSString *aptPackagesFile = [NSString stringWithFormat:@"/var/lib/apt/lists/%@_Packages", [repo repoBaseFileName]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:aptPackagesFile]) {
      aptPackagesFile = [NSString stringWithFormat:@"/var/lib/apt/lists/%@_main_binary-iphoneos-arm_Packages", [repo repoBaseFileName]]; //Do some funky package file with the default repos
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
  sqlite3 *database;
  sqlite3_open([_databasePath UTF8String], &database);
  sqlite3_exec(database, "DELETE FROM INSTALLED", NULL, NULL, NULL); //Delete all packages so we don't end up with duplicates
  sqlite3_config(SQLITE_CONFIG_SERIALIZED);

  AUPMPackageManager *packageManager = [[AUPMPackageManager alloc] init];
  NSArray *packagesArray = [packageManager installedPackageList];

  //(name text, packageid text, version text, section text, desc text, url text)
  //Might need to thread this process so that it doesn't freeze the UI but we will see how quick it is
  HBLogInfo(@"Started to parse installed packages");
  NSString *packageQuery = @"insert into installed(name, packageid, version, section, desc, url) values(?,?,?,?,?,?)";
  sqlite3_stmt *packageStatement;
  sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, NULL);
  if (sqlite3_prepare_v2(database, [packageQuery UTF8String], -1, &packageStatement, nil) == SQLITE_OK) {
    for (AUPMPackage *package in packagesArray) {
      //Populate packages database with packages from repo
      sqlite3_bind_text(packageStatement, 1, [[package packageName] UTF8String], -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(packageStatement, 2, [[package packageIdentifier] UTF8String], -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(packageStatement, 3, [[package version] UTF8String], -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(packageStatement, 4, [[package section] UTF8String], -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(packageStatement, 5, [[package description] UTF8String], -1, SQLITE_TRANSIENT);
      sqlite3_bind_text(packageStatement, 6, [[package depictionURL].absoluteString UTF8String], -1, SQLITE_TRANSIENT);
      sqlite3_step(packageStatement);
      sqlite3_reset(packageStatement);
      sqlite3_clear_bindings(packageStatement);
    }
    HBLogInfo(@"Finished installed packages");
  }
  else {
    HBLogError(@"%s", sqlite3_errmsg(database));
  }
  sqlite3_finalize(packageStatement);
  sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, NULL);
  sqlite3_close(database);
  completion(true);
}

- (sqlite3 *)database {
  sqlite3 *database;
  sqlite3_open([_databasePath UTF8String], &database);
  return database;
}

- (void)deletePackagesFromRepo:(AUPMRepo *)repo inDatabase:(sqlite3 *)database {
  sqlite3_exec(database, [[NSString stringWithFormat:@"DELETE FROM packages WHERE repoID = %d", [repo repoIdentifier]] UTF8String], NULL, NULL, NULL);
}

- (void)deleteRepo:(AUPMRepo *)repo fromDatabase:(sqlite3 *)database {
  sqlite3_exec(database, [[NSString stringWithFormat:@"DELETE FROM packages WHERE repoID = %d", [repo repoIdentifier]] UTF8String], NULL, NULL, NULL);
  sqlite3_exec(database, [[NSString stringWithFormat:@"DELETE FROM repos WHERE repoID = %d", [repo repoIdentifier]] UTF8String], NULL, NULL, NULL);
}

- (NSArray *)cachedListOfInstalledPackages {
  HBLogInfo(@"Getting cached list of installed pacakges");
  sqlite3 *database;
  sqlite3_open([_databasePath UTF8String], &database);
  NSMutableArray *listOfPackages = [[NSMutableArray alloc] init];
  NSString *query = @"SELECT * FROM installed";
  sqlite3_stmt *statement;
  if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
    while (sqlite3_step(statement) == SQLITE_ROW) {
      const char *packageNameChars = (const char *)sqlite3_column_text(statement, 0);
      const char *packageIDChars = (const char *)sqlite3_column_text(statement, 1);
      const char *versionChars = (const char *)sqlite3_column_text(statement, 2);
      const char *sectionChars = (const char *)sqlite3_column_text(statement, 3);
      const char *descriptionChars = (const char *)sqlite3_column_text(statement, 4);
      const char *depictionChars = (const char *)sqlite3_column_text(statement, 5);

      NSString *packageName;
      NSString *packageID = [[NSString alloc] initWithUTF8String:packageIDChars];
      if (packageNameChars == NULL)
      {
        packageName = packageID;
      }
      else
      {
        packageName = [[NSString alloc] initWithUTF8String:packageNameChars];
      }
      NSString *version = [[NSString alloc] initWithUTF8String:versionChars];
      NSString *section = [[NSString alloc] initWithUTF8String:sectionChars];
      NSString *description;
      if (description == NULL)
      {
        description = @"No Description";
      }
      else
      {
        description = [[NSString alloc] initWithUTF8String:descriptionChars];
      }
      NSString *depictionURL;
      if (depictionChars == NULL)
      {
        depictionURL = nil;
      }
      else
      {
        depictionURL = [[NSString alloc] initWithUTF8String:depictionChars];
      }
      //NSString *md5sum = [[NSString alloc] initWithUTF8String:sumChars];

      AUPMPackage *package = [[AUPMPackage alloc] initWithPackageName:packageName packageID:packageID version:version section:section description:description depictionURL:depictionURL sum:nil];
      [listOfPackages addObject:package];
    }
    sqlite3_finalize(statement);
  }
  else {
    HBLogError(@"%s", sqlite3_errmsg(database));
  }
  sqlite3_close(database);
  NSSortDescriptor *sortByPackageName = [NSSortDescriptor sortDescriptorWithKey:@"packageName" ascending:YES];
  NSArray *sortDescriptors = [NSArray arrayWithObject:sortByPackageName];

  return [listOfPackages sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray *)cachedListOfRepositories {
  HBLogInfo(@"Getting cached list of repos");
  sqlite3 *database;
  sqlite3_open([_databasePath UTF8String], &database);

  NSMutableArray *listOfRepositories = [[NSMutableArray alloc] init];
  NSString *query = @"SELECT * FROM repos";
  sqlite3_stmt *statement;
  //packageName, packageIdentifier, version, section, description, depictionURL
  if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
    while (sqlite3_step(statement) == SQLITE_ROW) {
      int uniqueId = sqlite3_column_int(statement, 0);
      const char *repoNameChars = (const char *)sqlite3_column_text(statement, 1);
      const char *repoFileNameChars = (const char *)sqlite3_column_text(statement, 2);
      const char *descriptionChars = (const char *)sqlite3_column_text(statement, 3);
      const char *repoURLChars = (const char *)sqlite3_column_text(statement, 4);
      NSString *repoName = [[NSString alloc] initWithUTF8String:repoNameChars];
      NSString *repoBaseFileName = [[NSString alloc] initWithUTF8String:repoFileNameChars];
      NSString *description = [[NSString alloc] initWithUTF8String:descriptionChars];
      NSString *repoURL = [[NSString alloc] initWithUTF8String:repoURLChars];
      NSData *repoIcon = [[NSData alloc] initWithBytes:sqlite3_column_blob(statement, 5) length:sqlite3_column_bytes(statement, 5)];
      AUPMRepo *repo = [[AUPMRepo alloc] initWithRepoID:uniqueId name:repoName baseFileName:repoBaseFileName description:description url:repoURL icon:repoIcon];
      [listOfRepositories addObject:repo];
    }
    sqlite3_finalize(statement);
  }
  else {
    HBLogError(@"%s", sqlite3_errmsg(database));
  }
  sqlite3_close(database);

  NSSortDescriptor *sortByRepoName = [NSSortDescriptor sortDescriptorWithKey:@"repoName" ascending:YES];
  NSArray *sortDescriptors = [NSArray arrayWithObject:sortByRepoName];

  return (NSArray*)[listOfRepositories sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray *)cachedPackageListForRepo:(AUPMRepo *)repo {
  HBLogInfo(@"Getting cached packages for repo");
  sqlite3 *database;
  sqlite3_open([_databasePath UTF8String], &database);
  NSMutableArray *listOfPackages = [[NSMutableArray alloc] init];
  NSString *query = @"SELECT * FROM packages WHERE repoID = ?";
  sqlite3_stmt *statement;
  if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
    sqlite3_bind_int(statement, 1, [repo repoIdentifier]);
    while (sqlite3_step(statement) == SQLITE_ROW) {
      //int uniqueId = sqlite3_column_int(statement, 0);
      const char *packageNameChars = (const char *)sqlite3_column_text(statement, 2);
      const char *packageIDChars = (const char *)sqlite3_column_text(statement, 3);
      const char *versionChars = (const char *)sqlite3_column_text(statement, 4);
      const char *sectionChars = (const char *)sqlite3_column_text(statement, 5);
      const char *descriptionChars = (const char *)sqlite3_column_text(statement, 6);
      const char *depictionChars = (const char *)sqlite3_column_text(statement, 7);
      // const char *sumChars = (const char *)sqlite3_column_text(statement, 9);
      // HBLogInfo(@"%s", sumChars);
      NSString *packageName = [[NSString alloc] initWithUTF8String:packageNameChars];
      NSString *packageID = [[NSString alloc] initWithUTF8String:packageIDChars];
      NSString *version = [[NSString alloc] initWithUTF8String:versionChars];
      NSString *section = [[NSString alloc] initWithUTF8String:sectionChars];
      NSString *description = [[NSString alloc] initWithUTF8String:descriptionChars];
      NSString *depictionURL;
      if (depictionChars == NULL)
      {
        depictionURL = nil;
      }
      else
      {
        depictionURL = [[NSString alloc] initWithUTF8String:depictionChars];
      }
      //NSString *md5sum = [[NSString alloc] initWithUTF8String:sumChars];

      AUPMPackage *package = [[AUPMPackage alloc] initWithPackageName:packageName packageID:packageID version:version section:section description:description depictionURL:depictionURL sum:nil];
      [listOfPackages addObject:package];
    }
    sqlite3_finalize(statement);
  }
  else {
    HBLogError(@"%s", sqlite3_errmsg(database));
  }
  sqlite3_close(database);
  AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];
  NSSortDescriptor *sortByPackageName = [NSSortDescriptor sortDescriptorWithKey:@"packageName" ascending:YES];
  NSArray *sortDescriptors = [NSArray arrayWithObject:sortByPackageName];

  return [[repoManager cleanUpDuplicatePackages:listOfPackages] sortedArrayUsingDescriptors:sortDescriptors];
}

- (void)copyDatabase:(NSString *)database intoDocumentsDirectory:(NSString *)directory {
  NSString *destinationPath = [directory stringByAppendingPathComponent:database];
  if (![[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) {
    NSString *sourcePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:database];
    NSError *error;
    [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:&error];

    if (error != nil) {
      HBLogError(@"%@", [error localizedDescription]);
    }
  }
}

- (void)purgeRecords {
  sqlite3 *database;
  sqlite3_open([_databasePath UTF8String], &database);
  sqlite3_exec(database, "DELETE FROM REPOS", NULL, NULL, NULL);
  sqlite3_exec(database, "DELETE FROM PACKAGES", NULL, NULL, NULL);
  sqlite3_close(database);
}

@end
