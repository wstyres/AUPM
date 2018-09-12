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
@property NSString *versionidentifier;
@property BOOL installed;
@property AUPMRepo *repo;
@end
RLM_ARRAY_TYPE(AUPMPackage)
