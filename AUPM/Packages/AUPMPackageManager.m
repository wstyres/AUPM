#import "AUPMPackageManager.h"

#import "AUPMPackage.h"
#import "NSTask.h"

@implementation AUPMPackageManager

NSArray *packages_to_array(const char *path);

//Parse installed package list from dpkg and create an AUPMPackage for each one and return an array
- (NSArray *)installedPackageList {
#if TARGET_OS_SIMULATOR
    NSString *dbPath = [[NSBundle mainBundle] pathForResource:@"status" ofType:@"tx"];
#else
    NSString *dbPath = @"/var/lib/dpkg/status";
#endif
    NSArray *packageArray = packages_to_array([dbPath UTF8String]);
    NSMutableArray *installedPackageList = [[NSMutableArray alloc] init];

    for (NSDictionary *dict in packageArray) {
        AUPMPackage *package = [AUPMPackage createWithDictionary:dict];

        package.installed = true;

        if ([dict[@"Status"] rangeOfString:@"deinstall"].location == NSNotFound && [dict[@"Status"] rangeOfString:@"not-installed"].location == NSNotFound && [dict[@"Package"] rangeOfString:@"saffron-jailbreak"].location == NSNotFound && [dict[@"Package"] rangeOfString:@"gsc"].location == NSNotFound && [dict[@"Package"] rangeOfString:@"cy+"].location == NSNotFound) {
            [installedPackageList addObject:package];
        }
    }

    NSSortDescriptor *sortByPackageName = [NSSortDescriptor sortDescriptorWithKey:@"packageName" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByPackageName];

    return (NSArray*)[installedPackageList sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray *)filesInstalledByPackage:(AUPMPackage *)package {
  NSTask *checkFilesTask = [[NSTask alloc] init];
  [checkFilesTask setLaunchPath:@"/Applications/AUPM.app/supersling"];
  NSArray *filesArgs = [[NSArray alloc] initWithObjects: @"dpkg", @"-L", [package packageIdentifier], nil];
  [checkFilesTask setArguments:filesArgs];

  NSPipe * out = [NSPipe pipe];
  [checkFilesTask setStandardOutput:out];

  [checkFilesTask launch];
  [checkFilesTask waitUntilExit];

  NSFileHandle *read = [out fileHandleForReading];
  NSData *dataRead = [read readDataToEndOfFile];
  NSString *stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];

  return [stringRead componentsSeparatedByString: @"\n"];
}

- (BOOL)packageHasTweak:(AUPMPackage *)package {
  NSArray *files = [self filesInstalledByPackage:package];

  for (NSString *path in files) {
    if ([path rangeOfString:@"/Library/MobileSubstrate/DynamicLibraries"].location != NSNotFound) {
      if ([path rangeOfString:@".dylib"].location != NSNotFound) {
        return true;
      }
    }
  }
  return false;
}

- (BOOL)packageHasApp:(AUPMPackage *)package {
  NSArray *files = [self filesInstalledByPackage:package];

  for (NSString *path in files) {
    if ([path rangeOfString:@".app/Info.plist"].location != NSNotFound) {
      return true;
    }
  }
  return false;
}

@end
