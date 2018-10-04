@class AUPMPackage;

@interface AUPMPackageManager : NSObject
- (NSArray *)installedPackageList;
- (BOOL)packageHasTweak:(AUPMPackage *)package;
- (BOOL)packageHasApp:(AUPMPackage *)package;
@end
