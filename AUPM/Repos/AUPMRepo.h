@interface AUPMRepo : NSObject {
    NSData *icon;
    NSString *repoName;
    NSString *repoBaseFileName;
    NSString *description;
    NSString *repoURL;
    int repoIdentifier;
    BOOL defaultRepo;
    NSString *suite;
    NSString *components;
    NSString *fullURL;
}
- (id)initWithRepoInformation:(NSDictionary *)information;
- (id)initWithRepoID:(int)identifier name:(NSString *)name baseFileName:(NSString *)baseFileName description:(NSString *)repoDescription url:(NSString *)url icon:(NSData *)icon;
- (NSURL *)iconURL;
- (void)setIcon:(NSData *)icon;
- (void)setRepoName:(NSString *)name;
- (void)setRepoBaseFileName:(NSString *)url;
- (void)setDescription:(NSString *)description;
- (void)setRepoURL:(NSString *)url;
- (void)setRepoID:(int)identifier;
- (void)setDefaultRepo:(BOOL)def;
- (void)setSuite:(NSString *)stab;
- (void)setComponents:(NSString *)comp;
- (void)setFullURL:(NSString *)url;
- (NSData *)icon;
- (NSString *)repoName;
- (NSString *)repoBaseFileName;
- (NSString *)description;
- (NSString *)repoURL;
- (int)repoIdentifier;
- (BOOL)defaultRepo;
- (NSString *)suite;
- (NSString *)components;
- (NSString *)fullURL;
@end
