#import "AUPMRepo.h"

@implementation AUPMRepo

- (id)initWithRepoInformation:(NSDictionary *)information {
    [self setIcon:information[@"Icon"]];
    [self setRepoName:information[@"Origin"]];
    [self setRepoBaseFileName:information[@"baseFileName"]];
    [self setDescription:information[@"Description"]];
    [self setRepoURL:information[@"URL"]];
    [self setDefaultRepo:(BOOL)information[@"default"]];
    [self setSuite:information[@"Suite"]];
    [self setComponents:information[@"Components"]];
    [self setFullURL:information[@"fullURL"]];

    return self;
}

- (id)initWithRepoID:(int)identifier name:(NSString *)name baseFileName:(NSString *)baseFileName description:(NSString *)repoDescription url:(NSString *)url icon:(NSData *)iconData {
    [self setRepoID:identifier];
    [self setRepoName:name];
    [self setRepoBaseFileName:baseFileName];
    [self setDescription:repoDescription];
    [self setRepoURL:url];
    [self setIcon:iconData];

    return self;
}

- (NSURL *)iconURL {
    if (fullURL != NULL) {
        return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/CydiaIcon.png", fullURL]];
    }
    else {
        return NULL;
    }
}

- (void)setSuite:(NSString *)stab {
    if (stab != NULL) {
        suite = stab;
    }
}

- (void)setComponents:(NSString *)comp {
    if (comp != NULL) {
        components = comp;
    }
}

- (void)setDefaultRepo:(BOOL)def {
    defaultRepo = def;
}

- (void)setRepoID:(int)identifier {
    repoIdentifier = identifier;
}

- (void)setIcon:(NSData *)ico {
    if (ico != NULL) {
        icon = ico;
    }
}

- (void)setRepoName:(NSString *)name {
    if (name != NULL) {
        repoName = name;
    }
}

- (void)setRepoBaseFileName:(NSString *)filename {
    if (filename != NULL) {
        repoBaseFileName = filename;
    }
}

- (void)setDescription:(NSString *)desc {
    if (desc != NULL) {
        description = desc;
    }
}

- (void)setRepoURL:(NSString *)url {
    if (url != NULL) {
        repoURL = url;
    }
}

- (void)setFullURL:(NSString *)url {
    if (url != NULL) {
        fullURL = [url stringByReplacingOccurrencesOfString:@"/." withString:@"/"];
    }
}

- (NSString *)components {
    return components;
}

- (NSString *)suite {
    return suite;
}

- (BOOL)defaultRepo {
    return defaultRepo;
}

- (int)repoIdentifier {
    return repoIdentifier;
}

- (NSData *)icon {
    return icon;
}

- (NSString *)repoName {
    return repoName;
}

- (NSString *)repoBaseFileName {
    return repoBaseFileName;
}

- (NSString *)description {
    return description;
}

- (NSString *)repoURL {
    return repoURL;
}

- (NSString *)fullURL {
    return fullURL;
}
@end
