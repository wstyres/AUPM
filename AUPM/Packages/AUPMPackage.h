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
@property NSString *versionidentifier;
@property BOOL installed;
@property AUPMRepo *repo;
@property AUPMDateKeeper *dateKeeper;
@end
RLM_ARRAY_TYPE(AUPMPackage)
