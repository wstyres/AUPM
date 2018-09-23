#import <WebKit/WebKit.h>
#import <MessageUI/MessageUI.h>

@interface AUPMWebViewController : UIViewController <WKScriptMessageHandler, MFMailComposeViewControllerDelegate>
- (id)initWithURL:(NSURL *)url;
@end
