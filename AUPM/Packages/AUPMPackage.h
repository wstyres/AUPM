#import <Realm/Realm.h>

@class AUPMRepo;

@interface AUPMPackage : RLMObject
@property NSString *packageName;
@property NSString *packageIdentifier;
@property NSString *version;
@property NSString *section;
@property NSString *description;
@property NSURL *depictionURL;
@property BOOL installed;
@property AUPMRepo *repo;
@end
RLM_ARRAY_TYPE(AUPMPackage)
