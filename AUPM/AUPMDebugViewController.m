#import "AUPMDebugViewController.h"
#import "AUPMRefreshViewController.h"
#import <Realm/Realm.h>
#define aupmVersion @"1.0~beta1"

@implementation AUPMDebugViewController {
  WKWebView *_webView;
}

- (void)loadView {
  [super loadView];

  [self.view setBackgroundColor:[UIColor whiteColor]]; //Fixes a weird animation issue when pushing

  WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
  WKUserContentController *controller = [[WKUserContentController alloc] init];
  [controller addScriptMessageHandler:self name:@"observe"];
  configuration.userContentController = controller;

  _webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:configuration];
  [_webView loadHTMLString:[self generateHomepage] baseURL:nil];

  [self.view addSubview:_webView];

  self.title = @"AUPM Beta";
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        _webView.frame = self.view.frame;
    } completion:nil];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSString *action = message.body;
    if ([action isEqualToString:@"nuke"]) {
      [self nukeDatabase];
    }
    else if ([action isEqualToString:@"sendBug"]) {
      [self sendBugReport];
    }
}

- (NSString *)generateHomepage {
	NSError *error;
	NSString *rawDepiction = [NSString stringWithContentsOfFile:@"/Applications/AUPM.app/home.html" encoding:NSUTF8StringEncoding error:&error];
	if (error != nil) {
		HBLogError(@"Error reading file: %@", error);
	}

	NSString *html = [NSString stringWithFormat:rawDepiction, aupmVersion];

	return html;
}

- (void)nukeDatabase {
  AUPMRefreshViewController *refreshViewController = [[AUPMRefreshViewController alloc] init];

  [[UIApplication sharedApplication] keyWindow].rootViewController = refreshViewController;
}

- (void)sendBugReport {
  if ([MFMailComposeViewController canSendMail]) {
    NSString *iosVersion = [NSString stringWithFormat:@"%@ running iOS %@", [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion]];
    RLMRealmConfiguration *config = [[RLMRealm defaultRealm] configuration];
    NSString *databaseLocation = [[config fileURL] absoluteString];
    NSString *message = [NSString stringWithFormat:@"iOS Version: %@\nAUPM Version: %@\nAUPM Database Location: %@\n\nPlease describe the bug you are experiencing or feature you are requesting below: \n\n", iosVersion, aupmVersion, databaseLocation];

    MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
    mail.mailComposeDelegate = self;
    [mail setSubject:@"AUPM Beta Bug Report"];
    [mail setMessageBody:message isHTML:NO];
    [mail setToRecipients:@[@"wilson@styres.me"]];

    [self presentViewController:mail animated:YES completion:NULL];
  }
  else
  {
    NSLog(@"[AUPM] This device cannot send email");
  }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
