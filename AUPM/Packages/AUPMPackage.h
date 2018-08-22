#import "../NSTask.h"

@interface AUPMPackage : NSObject {
    NSString *packageName;
    NSString *packageID;
    NSString *version;
    NSString *section;
    NSString *description;
    NSURL *depictionURL;
    NSString *sum;
    BOOL isLoadedInstall;
}
- (id)initWithPackageInformation:(NSDictionary *)information;
- (id)initWithPackageName:(NSString *)name packageID:(NSString *)identifier version:(NSString *)vers section:(NSString *)sect description:(NSString *)desc depictionURL:(NSString *)url sum:(NSString *)md5;
- (BOOL)isInstalled;
- (void)setPackageName:(NSString *)name;
- (void)setPackageIdentifier:(NSString *)identifier;
- (void)setPackageVersion:(NSString *)version;
- (void)setSection:(NSString *)section;
- (void)setDescription:(NSString *)description;
- (void)setDepictionURL:(NSURL *)url;
- (void)setSum:(NSString *)sum;
- (void)setLoadedInstall:(BOOL)inst;
- (NSString *)packageName;
- (NSString *)packageIdentifier;
- (NSString *)version;
- (NSString *)section;
- (NSString *)description;
- (NSURL *)depictionURL;
- (NSString *)sum;
- (BOOL)isLoadedInstall;
@end
