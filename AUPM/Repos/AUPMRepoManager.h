#import <Realm/Realm.h>
#import "../NSTask.h"

@class AUPMRepo;
@class AUPMPackage;

@interface AUPMRepoManager : NSObject
+ (id)sharedInstance;
- (id)init;
- (NSArray *)managedRepoList;
- (NSArray<AUPMPackage *> *)packageListForRepo:(AUPMRepo *)repo;
- (NSArray *)cleanUpDuplicatePackages:(NSArray *)packageList;
// - (void)addSource:(NSURL *)sourceURL;
// - (void)deleteSource:(AUPMRepo *)delRepo;
@end
