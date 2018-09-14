#import <sqlite3.h>
#import <pthread.h>
#import <Realm/Realm.h>

@class AUPMRepo;
@class AUPMPackage;

@interface AUPMDatabaseManager : NSObject
@property (nonatomic) long long lastInsertedRowID;

- (void)firstLoadPopulation:(void (^)(BOOL success))completion;
- (void)updatePopulation:(void (^)(BOOL success))completion;
// - (void)deletePackagesFromRepo:(AUPMRepo *)repo inDatabase:(sqlite3 *)database;
// - (void)deleteRepo:(AUPMRepo *)repo fromDatabase:(sqlite3 *)database;
@end
