#import <Realm/Realm.h>

@class AUPMPackage;
@protocol AUPMPackage;

@interface AUPMRepo : RLMObject
@property NSString *repoName;
@property NSString *repoBaseFileName;
@property NSString *repoDescription;
@property NSString *repoURL;
@property int repoIdentifier;
@property BOOL defaultRepo;
@property NSString *suite;
@property NSString *components;
@property NSString *fullURL;
@property NSData *icon;
@property RLMArray<AUPMPackage *><AUPMPackage> *packages;
@end
RLM_ARRAY_TYPE(AUPMRepo)
