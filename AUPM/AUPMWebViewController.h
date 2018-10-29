#import <WebKit/WebKit.h>
#import <MessageUI/MessageUI.h>
#import <Realm/Realm.h>

@interface AUPMWebViewController : UIViewController <WKNavigationDelegate, WKScriptMessageHandler, MFMailComposeViewControllerDelegate>
- (id)initWithURL:(NSURL *)url;
@end
