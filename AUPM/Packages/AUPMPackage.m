#import "AUPMPackage.h"

@implementation AUPMPackage

- (id)initWithPackageInformation:(NSDictionary *)information {
    [self setPackageName:information[@"Name"]];
    [self setPackageIdentifier:information[@"Package"]];
    [self setPackageVersion:information[@"Version"]];
    [self setSection:information[@"Section"]];
    [self setDescription:information[@"Description"]];

    NSString *urlString = [information[@"Depiction"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    //NSString *webStringURL = [webName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    urlString = [urlString substringToIndex:[urlString length] - 3];
    NSURL *url = [NSURL URLWithString:urlString];
    [self setDepictionURL:url];
    [self setSum:information[@"MD5sum"]];

    return self;
}

- (id)initWithPackageName:(NSString *)name packageID:(NSString *)identifier version:(NSString *)vers section:(NSString *)sect description:(NSString *)desc depictionURL:(NSString *)url sum:(NSString *)md5 {
    [self setPackageName:name];
    [self setPackageIdentifier:identifier];
    [self setPackageVersion:vers];
    [self setSection:sect];
    [self setDescription:desc];
    [self setDepictionURL:[NSURL URLWithString:url]];
    [self setSum:md5];

    return self;
}

- (BOOL)isInstalled {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/Applications/AUPM.app/supersling"];
    NSArray *arguments = [[NSArray alloc] initWithObjects: @"dpkg", @"-l", nil];
    [task setArguments:arguments];

    NSPipe *out = [NSPipe pipe];
    [task setStandardOutput:out];

    [task launch];
    [task waitUntilExit];

    NSData *data = [[out fileHandleForReading] readDataToEndOfFile];
    NSString *outputString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    if ([outputString rangeOfString:packageID].location != NSNotFound) {
        return true;
    }
    return false;
}

- (void)setPackageName:(NSString *)name {
    if (name != NULL) {
        packageName = name;
    }
    else {
        packageName = @"";
    }
}

- (void)setPackageIdentifier:(NSString *)identifier {
    if (identifier != NULL) {
        packageID = identifier;
    }
    else {
        packageID = @"";
    }
}

- (void)setPackageVersion:(NSString *)vers {
    if (vers != NULL) {
        version = vers;
    }
    else {
        version = @"";
    }
}

- (void)setSection:(NSString *)sect {
    if (sect != NULL) {
        section = sect;
    }
    else {
        section = @"";
    }
}

- (void)setDescription:(NSString *)desc {
    if (desc != NULL) {
        description = desc;
    }
    else {
        description = @"";
    }
}

- (void)setDepictionURL:(NSURL *)url {
    depictionURL = url;
}

- (void)setSum:(NSString *)md5 {
    if (md5 != NULL) {
        sum = md5;
    }
    else {
        sum = @"";
    }
}

- (NSString *)packageName {
    return packageName;
}

- (NSString *)packageIdentifier {
    return packageID;
}

- (NSString *)version {
    return version;
}

- (NSString *)section {
    return section;
}

- (NSString *)description {
    return description;
}

- (NSURL *)depictionURL {
    if ([[[depictionURL absoluteString] substringWithRange:NSMakeRange(0, 1)] isEqual:@"/"] && depictionURL != NULL) {
        NSString *fixed = [@"http:" stringByAppendingString:[depictionURL absoluteString]];
        [self setDepictionURL:[NSURL URLWithString:fixed]];
        HBLogInfo(@"Fixing depiction url %@", fixed);
        return depictionURL;
    }
    else {
        return depictionURL;
    }
}

- (NSString *)sum {
    return sum;
}

@end
