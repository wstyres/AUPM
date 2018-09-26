#import "AUPMRepo.h"
#import "../Packages/AUPMPackage.h"

@implementation AUPMRepo
+ (NSString *)primaryKey {
    return @"repoBaseFileName";
}
- (RLMResults<AUPMPackage *> *)packages {
  return [AUPMPackage objectsWhere:@"repo == %@", self];
}
@end
