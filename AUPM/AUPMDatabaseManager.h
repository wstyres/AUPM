#import <sqlite3.h>
#import <pthread.h>
#import <Realm/Realm.h>

@class AUPMRepo;
@class AUPMPackage;

@interface AUPMDatabaseManager : NSObject
@property (nonatomic) long long lastInsertedRowID;

- (void)firstLoadPopulation:(void (^)(BOOL success))completion;
// - (void)updatePopulation:(void (^)(BOOL success))completion;
- (RLMResults *)cachedListOfRepositories;
- (RLMArray<AUPMPackage *> *)cachedPackageListForRepo:(AUPMRepo *)repo;
// - (sqlite3 *)database;
// - (void)deletePackagesFromRepo:(AUPMRepo *)repo inDatabase:(sqlite3 *)database;
// - (void)deleteRepo:(AUPMRepo *)repo fromDatabase:(sqlite3 *)database;
- (RLMResults<AUPMPackage *> *)cachedListOfInstalledPackages;
@end
