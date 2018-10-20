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
@property NSString *tags;
@property BOOL installed;
@property AUPMRepo *repo;
- (BOOL)isInstalled;
- (BOOL)isFromRepo;
@end
RLM_ARRAY_TYPE(AUPMPackage)
