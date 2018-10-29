#import <Realm/Realm.h>
#import "../NSTask.h"

@class AUPMRepo;
@class AUPMPackage;

@interface AUPMRepoManager : NSObject
- (id)init;
- (NSArray *)managedRepoList;
- (NSArray<AUPMPackage *> *)packageListForRepo:(AUPMRepo *)repo;
- (NSArray *)cleanUpDuplicatePackages:(NSArray *)packageList;
- (void)addSource:(NSURL *)sourceURL completion:(void (^)(BOOL success))completion;
- (void)deleteSource:(AUPMRepo *)delRepo;
@end
