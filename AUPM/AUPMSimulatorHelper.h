@class AUPMPackage;
@class AUPMRepo;

@interface AUPMSimulatorHelper : NSObject
+ (NSArray *)managedRepoList;
+ (NSArray<AUPMPackage *> *)packageListForRepo:(AUPMRepo *)repo;
@end
