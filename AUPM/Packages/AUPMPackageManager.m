#import "AUPMPackageManager.h"
#import "AUPMPackage.h"

@implementation AUPMPackageManager

NSArray *packages_to_array(const char *path);

//Parse installed package list from dpkg and create an AUPMPackage for each one and return an array
- (NSArray *)installedPackageList {
    NSString *dbPath = @"/var/lib/dpkg/status";
    NSArray *packageArray = packages_to_array([dbPath UTF8String]);
    NSMutableArray *installedPackageList = [[NSMutableArray alloc] init];

    for (NSDictionary *dict in packageArray) {
        AUPMPackage *package = [[AUPMPackage alloc] init];
        if (dict[@"Name"] == NULL) {
          package.packageName = [dict[@"Package"] substringToIndex:[dict[@"Package"] length] - 1];
        }
        else {
          package.packageName = [dict[@"Name"] substringToIndex:[dict[@"Name"] length] - 1];
        }

        package.packageIdentifier = [dict[@"Package"] substringToIndex:[dict[@"Package"] length] - 1];
        package.version = [dict[@"Version"] substringToIndex:[dict[@"Version"] length] - 1];
        package.section = [dict[@"Section"] substringToIndex:[dict[@"Section"] length] - 1];
        package.packageDescription = [dict[@"Description"] substringToIndex:[dict[@"Description"] length] - 1];
        package.versionidentifier = [NSString stringWithFormat:@"%@~%@", dict[@"Version"], dict[@"Package"]];

        NSString *urlString = [dict[@"Depiction"] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        urlString = [urlString substringToIndex:[urlString length] - 3]; //idk why this is here
        package.depictionURL = urlString;
        package.installed = true;

        if ([dict[@"Status"] rangeOfString:@"deinstall"].location == NSNotFound && [dict[@"Status"] rangeOfString:@"not-installed"].location == NSNotFound && [dict[@"Package"] rangeOfString:@"gsc"].location == NSNotFound && [dict[@"Package"] rangeOfString:@"cy+"].location == NSNotFound) {
            [installedPackageList addObject:package];
        }
    }

    NSSortDescriptor *sortByPackageName = [NSSortDescriptor sortDescriptorWithKey:@"packageName" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByPackageName];

    return (NSArray*)[installedPackageList sortedArrayUsingDescriptors:sortDescriptors];
}

@end
