#import "AUPMPackage.h"

@implementation AUPMPackage

+ (AUPMPackage *)createWithDictionary:(NSDictionary *)dict {
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
  package.repoVersion = [NSString stringWithFormat:@"local~%@", dict[@"Package"]];

  package.tags = [dict[@"Tag"] substringToIndex:[dict[@"Tag"] length] - 1];

  NSString *urlString = [dict[@"Depiction"] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
  urlString = [urlString substringToIndex:[urlString length] - 3]; //idk why this is here
  package.depictionURL = urlString;

  return package;
}

+ (NSString *)primaryKey {
    return @"repoVersion";
}

- (BOOL)isInstalled {
  if ([self installed])
    return true;

  return ([[AUPMPackage objectsWhere:@"packageIdentifier == %@ AND version == %@", [self packageIdentifier], [self version]] count] > 1);
}

- (BOOL)isFromRepo {
  if ([self repo] != NULL)
    return true;

  return ([[AUPMPackage objectsWhere:@"packageIdentifier == %@ AND version == %@", [self packageIdentifier], [self version]] count] > 1);
}

@end
