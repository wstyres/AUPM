#import <sqlite3.h>
#import <pthread.h>
#import <Realm/Realm.h>

@class AUPMRepo;
@class AUPMPackage;

@interface AUPMDatabaseManager : NSObject {
  BOOL _hasPackagesThatNeedUpdates;
  int _numberOfPackagesThatNeedUpdates;
  NSArray *_updateObjects;
}
- (void)firstLoadPopulation:(void (^)(BOOL success))completion;
- (void)updatePopulation:(void (^)(BOOL success))completion;
- (void)updateEssentials:(void (^)(BOOL success))completion;
- (void)deleteRepo:(AUPMRepo *)repo;
- (BOOL)hasPackagesThatNeedUpdates;
- (int)numberOfPackagesThatNeedUpdates;
- (NSArray *)updateObjects;
@end
