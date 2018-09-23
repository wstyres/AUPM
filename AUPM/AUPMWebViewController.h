#import <WebKit/WebKit.h>
#import <MessageUI/MessageUI.h>

@interface AUPMWebViewController : UIViewController <WKNavigationDelegate, WKScriptMessageHandler, MFMailComposeViewControllerDelegate>
- (id)initWithURL:(NSURL *)url;
@end
