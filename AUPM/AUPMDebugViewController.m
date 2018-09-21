#import "AUPMDebugViewController.h"
#import "AUPMRefreshViewController.h"

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

	NSString *html = [NSString stringWithFormat:rawDepiction, @"1.0~beta1"];

	return html;
}

- (void)nukeDatabase {
  AUPMRefreshViewController *refreshViewController = [[AUPMRefreshViewController alloc] init];

  [[UIApplication sharedApplication] keyWindow].rootViewController = refreshViewController;
}

- (void)sendBugReport {
  if ([MFMailComposeViewController canSendMail])
  {
    MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
    mail.mailComposeDelegate = self;
    [mail setSubject:@"AUPM Beta"];
    [mail setMessageBody:@"" isHTML:NO];
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
