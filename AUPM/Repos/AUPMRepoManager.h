@class AUPMRepo;

@interface AUPMRepoManager : NSObject
+ (id)sharedInstance;
- (id)init;
- (NSArray *)managedRepoList;
- (NSArray *)packageListForRepo:(AUPMRepo *)repo;
- (NSArray *)cleanUpDuplicatePackages:(NSArray *)packageList;
- (void)addSource:(NSURL *)sourceURL;
- (void)deleteSource:(AUPMRepo *)delRepo;
@end
