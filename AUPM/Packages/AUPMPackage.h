#import <Realm/Realm.h>

@class AUPMRepo;
@protocol AUPMRepo;

@interface AUPMPackage : RLMObject
@property NSString *packageName;
@property NSString *packageIdentifier;
@property NSString *version;
@property NSString *section;
@property NSString *packageDescription;
@property NSString *depictionURL;
@property NSString *repoVersion;
@property BOOL installed;
@property AUPMRepo *repo;
- (BOOL)isInstalled;
@end
RLM_ARRAY_TYPE(AUPMPackage)
