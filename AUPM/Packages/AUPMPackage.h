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
@property NSString *tags;
@property NSString *maintainer;
@property NSString *filename;
@property int installedSize;
@property NSString *depends;
@property NSString *conflicts;
@property NSString *repoVersion;
@property BOOL installed;
@property AUPMRepo *repo;
+ (AUPMPackage *)createWithDictionary:(NSDictionary *)dict;
- (BOOL)isInstalled;
- (BOOL)isFromRepo;
@end
RLM_ARRAY_TYPE(AUPMPackage)
