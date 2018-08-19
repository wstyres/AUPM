#import <WebKit/WebKit.h>
@class AUPMPackage;

@interface AUPMPackageViewController : UIViewController <WKNavigationDelegate>
- (id)initWithPackage:(AUPMPackage *)package;
@end
