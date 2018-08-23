#import "AUPMRepoManager.h"
#import "AUPMRepo.h"
#import "../Packages/AUPMPackage.h"
#include "dpkgver.c"
#import "../AUPMDatabaseManager.h"

@interface AUPMRepoManager ()
    @property (nonatomic, retain) NSMutableArray *repos;
@end

@implementation AUPMRepoManager

NSArray *packages_to_array(const char *path);

+ (id)sharedInstance {
    static AUPMRepoManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [AUPMRepoManager new];
    });
    return instance;
}

- (id)init {
    self = [super init];

    if (self) {
        self.repos = [[self managedRepoList] mutableCopy];
    }

    return self;
}

- (NSArray *)managedRepoList {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *aptListDirectory = @"/var/lib/apt/lists";
    NSArray *listOfFiles = [fileManager contentsOfDirectoryAtPath:aptListDirectory error:nil];
    NSMutableArray *managedRepoList = [[NSMutableArray alloc] init];

    for (NSString *path in listOfFiles) {
        if (([path rangeOfString:@"Release"].location != NSNotFound) && ([path rangeOfString:@".gpg"].location == NSNotFound)) {
            NSString *fullPath = [NSString stringWithFormat:@"/var/lib/apt/lists/%@", path];
            NSString *content = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:NULL];

            NSString *trimmedString = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSArray *keyValuePairs = [trimmedString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];

            for (NSString *keyValuePair in keyValuePairs) {
                NSString *trimmedPair = [keyValuePair stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

                NSArray *keyValues = [trimmedPair componentsSeparatedByString:@":"];

                dict[[keyValues.firstObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]] = [keyValues.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            }

            NSString *baseFileName = [path stringByReplacingOccurrencesOfString:@"_Release" withString:@""];
            dict[@"baseFileName"] = baseFileName;
            NSString *fullRepoURL = baseFileName;
            fullRepoURL = [fullRepoURL stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
            dict[@"fullURL"] = fullRepoURL; //Store full URL for cydia icon
            NSString *repoURL = [fullRepoURL copy];
            if ([repoURL rangeOfString:@"dists"].location != NSNotFound) {
                NSArray *urlsep = [repoURL componentsSeparatedByString:@"dists"];
                repoURL = [urlsep objectAtIndex:0];
                repoURL = [repoURL stringByAppendingString:@"/"];
            }
            repoURL = [NSString stringWithFormat:@"http://%@", repoURL];
            repoURL = [repoURL substringToIndex:[repoURL length] - 1];
            dict[@"URL"] = repoURL;
            if ([baseFileName rangeOfString:@"saurik"].location != NSNotFound || [baseFileName rangeOfString:@"bigboss"].location != NSNotFound || [baseFileName rangeOfString:@"zodttd"].location != NSNotFound) {
                dict[@"default"] = [NSNumber numberWithBool:true];
            }

            AUPMRepo *source = [[AUPMRepo alloc] initWithRepoInformation:dict];
            [managedRepoList addObject:source];
        }
    }

    NSSortDescriptor *sortByRepoName = [NSSortDescriptor sortDescriptorWithKey:@"repoName" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByRepoName];

    return (NSArray*)[managedRepoList sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray *)cleanUpDuplicatePackages:(NSArray *)packageList {
    NSMutableDictionary *packageVersionDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *cleanedPackageList = [packageList mutableCopy];

    for (AUPMPackage *package in packageList) {
        if (packageVersionDict[[package packageIdentifier]] == NULL) {
            packageVersionDict[[package packageIdentifier]] = package;
        }

        NSString *arrayVersion = [(AUPMPackage *)packageVersionDict[[package packageIdentifier]] version];
        NSString *packageVersion = [package version];
        int result = verrevcmp([packageVersion UTF8String], [arrayVersion UTF8String]);

        if (result > 0) {
            [cleanedPackageList removeObject:packageVersionDict[[package packageIdentifier]]];
            packageVersionDict[[package packageIdentifier]] = package;
        }
        else if (result < 0) {
            [cleanedPackageList removeObject:package];
        }
    }

    return (NSArray *)cleanedPackageList;
}

- (NSArray *)packageListForRepo:(AUPMRepo *)repo {
    NSString *cachedPackagesFile = [NSString stringWithFormat:@"/var/lib/apt/lists/%@_Packages", [repo repoBaseFileName]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachedPackagesFile]) {
        cachedPackagesFile = [NSString stringWithFormat:@"/var/lib/apt/lists/%@_main_binary-iphoneos-arm_Packages", [repo repoBaseFileName]]; //Do some funky package file with the default repos
    }

    NSArray *packageArray = packages_to_array([cachedPackagesFile UTF8String]);
    NSMutableArray *packageListForRepo = [[NSMutableArray alloc] init];

    for (NSDictionary *package in packageArray) {
        NSMutableDictionary *dict = [package mutableCopy];
        if (dict[@"Name"] == NULL) {
            dict[@"Name"] = dict[@"Package"];
        }

        if ([dict[@"Package"] rangeOfString:@"gsc"].location == NSNotFound && [dict[@"Package"] rangeOfString:@"cy+"].location == NSNotFound) {                AUPMPackage *package = [[AUPMPackage alloc] initWithPackageInformation:dict];
            [packageListForRepo addObject:package];
        }
    }

    return packageListForRepo;
}

- (void)addSource:(NSURL *)sourceURL {
    NSString *URL = [sourceURL absoluteString];
    NSString *output = @"";

    for (AUPMRepo *repo in _repos) {
        if ([repo defaultRepo]) {
            if ([[repo repoName] isEqual:@"Cydia/Telesphoreo"]) {
                output = [output stringByAppendingFormat:@"deb http://apt.saurik.com/ ios/%.2f main\n",kCFCoreFoundationVersionNumber];
            }
            else {
                output = [output stringByAppendingFormat:@"deb %@ %@ %@\n", [repo repoURL], [repo suite], [repo components]];
            }
        }
        else {
            output = [output stringByAppendingFormat:@"deb %@ ./\n", [repo repoURL]];
        }
    }
    output = [output stringByAppendingFormat:@"deb %@/ ./\n", URL];

    NSError *error;
    [output writeToFile:@"/var/mobile/Library/Caches/com.xtm3x.aupm/newsources.list" atomically:TRUE encoding:NSUTF8StringEncoding error:&error];
    if (error != NULL) {
        HBLogError(@"Error while writing sources to file: %@", error);
    }
    else {
        NSTask *updateListTask = [[NSTask alloc] init];
        [updateListTask setLaunchPath:@"/Applications/AUPM.app/supersling"];
        NSArray *updateArgs = [[NSArray alloc] initWithObjects:@"cp", @"/var/mobile/Library/Caches/com.xtm3x.aupm/newsources.list", @"/etc/apt/sources.list.d/cydia.list", nil];
        [updateListTask setArguments:updateArgs];

        [updateListTask launch];
        [updateListTask waitUntilExit];
    }
}

- (void)deleteSource:(AUPMRepo *)delRepo {
    NSString *output = @"";
    for (AUPMRepo *repo in _repos) {
        if ([[delRepo repoBaseFileName] isEqual:[repo repoBaseFileName]]) {
            [_repos removeObject:repo];
        }
        else {
            if ([repo defaultRepo]) {
                if ([[repo repoName] isEqual:@"Cydia/Telesphoreo"]) {
                    output = [output stringByAppendingFormat:@"deb http://apt.saurik.com/ ios/%.2f main\n",kCFCoreFoundationVersionNumber];
                }
                else {
                    output = [output stringByAppendingFormat:@"deb %@ %@ %@\n", [repo repoURL], [repo suite], [repo components]];
                }
            }
            else {
                output = [output stringByAppendingFormat:@"deb %@ ./\n", [repo repoURL]];
            }
        }
    }

    NSError *error;
    [output writeToFile:@"/var/mobile/Library/Caches/com.xtm3x.aupm/newsources.list" atomically:TRUE encoding:NSUTF8StringEncoding error:&error];
    if (error != NULL) {
        HBLogError(@"Error while writing sources to file: %@", error);
    }
    else {
        NSTask *updateListTask = [[NSTask alloc] init];
        [updateListTask setLaunchPath:@"/Applications/AUPM.app/supersling"];
        NSArray *updateArgs = [[NSArray alloc] initWithObjects:@"cp", @"/var/mobile/Library/Caches/com.xtm3x.aupm/newsources.list", @"/etc/apt/sources.list.d/cydia.list", nil];
        [updateListTask setArguments:updateArgs];

        [updateListTask launch];
        [updateListTask waitUntilExit];
    }

    AUPMDatabaseManager *databaseManager = [[AUPMDatabaseManager alloc] init];
	  sqlite3 *database = [databaseManager database];
    [databaseManager deleteRepo:delRepo fromDatabase:database];
    sqlite3_close(database);
}

@end
