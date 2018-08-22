#import <sqlite3.h>
#import <pthread.h>

@class AUPMRepo;

@interface AUPMDatabaseManager : NSObject
@property (nonatomic) long long lastInsertedRowID;

- (void)firstLoadPopulation:(void (^)(BOOL success))completion;
- (void)updatePopulation:(void (^)(BOOL success))completion;
- (NSArray *)cachedListOfRepositories;
- (NSArray *)cachedPackageListForRepo:(AUPMRepo *)repo;
- (sqlite3 *)database;
- (void)deletePackagesFromRepo:(AUPMRepo *)repo inDatabase:(sqlite3 *)database;
- (void)deleteRepo:(AUPMRepo *)repo fromDatabase:(sqlite3 *)database;
@end
