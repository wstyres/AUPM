#import <Realm/Realm.h>
#import "../NSTask.h"

@class AUPMRepo;
@class AUPMPackage;

@interface AUPMRepoManager : NSObject
- (id)init;
- (NSArray *)managedRepoList;
- (NSArray<AUPMPackage *> *)packageListForRepo:(AUPMRepo *)repo;
- (NSArray *)cleanUpDuplicatePackages:(NSArray *)packageList;
- (void)addSourceWithURL:(NSString *)url response:(void (^)(BOOL success, NSString *error, NSURL *url))response;
- (void)deleteSource:(AUPMRepo *)delRepo;
@end
