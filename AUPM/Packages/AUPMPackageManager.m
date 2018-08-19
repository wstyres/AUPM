#import "AUPMPackageManager.h"
#import "AUPMPackage.h"

@implementation AUPMPackageManager

NSArray *packages_to_array(const char *path);

//Parse installed package list from dpkg and create an AUPMPackage for each one and return an array
- (NSArray *)installedPackageList {
    NSString *dbPath = @"/var/lib/dpkg/status";
    NSArray *packageArray = packages_to_array([dbPath UTF8String]);
    NSMutableArray *installedPackageList = [[NSMutableArray alloc] init];

    for (NSDictionary *pack in packageArray) {
        NSMutableDictionary *dict = [pack mutableCopy];
        if (dict[@"Name"] == NULL) {
            dict[@"Name"] = dict[@"Package"];
        }

        if ([dict[@"Package"] rangeOfString:@"gsc"].location == NSNotFound && [dict[@"Package"] rangeOfString:@"cy+"].location == NSNotFound) {
            AUPMPackage *package = [[AUPMPackage alloc] initWithPackageInformation:dict];
            [installedPackageList addObject:package];
        }
    }

    NSSortDescriptor *sortByPackageName = [NSSortDescriptor sortDescriptorWithKey:@"packageName" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByPackageName];

    return (NSArray*)[installedPackageList sortedArrayUsingDescriptors:sortDescriptors];
}

@end
