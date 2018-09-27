#import <Realm/Realm.h>

@class AUPMRepo;
@class AUPMDateKeeper;
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
@property AUPMDateKeeper *dateKeeper;
- (BOOL)isInstalled;
@end
RLM_ARRAY_TYPE(AUPMPackage)
