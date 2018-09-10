#import <WebKit/WebKit.h>
#import "../NSTask.h"
@class AUPMPackage;

@interface AUPMPackageViewController : UIViewController <WKNavigationDelegate>
- (id)initWithPackage:(AUPMPackage *)package;
@end
