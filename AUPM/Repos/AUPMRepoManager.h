#import <Realm/Realm.h>

@class AUPMRepo;
@class AUPMPackage;

@interface AUPMRepoManager : NSObject
+ (id)sharedInstance;
- (id)init;
- (NSArray *)managedRepoList;
- (RLMArray<AUPMPackage *> *)packageListForRepo:(AUPMRepo *)repo;
- (NSArray *)cleanUpDuplicatePackages:(NSArray *)packageList;
- (void)addSource:(NSURL *)sourceURL;
- (void)deleteSource:(AUPMRepo *)delRepo;
@end
