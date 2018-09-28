#import "AUPMWebViewController.h"
#import "AUPMRefreshViewController.h"
#import <Realm/Realm.h>

@implementation AUPMWebViewController {
  WKWebView *_webView;
  NSURL *_url;
}

- (id)init {
    self = [super init];

    return self;
}

- (id)initWithURL:(NSURL *)url {
  self = [super init];
  if (self) {
      _url = url;
  }
  return self;
}

- (void)loadView {
  [super loadView];

  [self.view setBackgroundColor:[UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0]]; //Fixes a weird animation issue when pushing

  WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
  WKUserContentController *controller = [[WKUserContentController alloc] init];
  [controller addScriptMessageHandler:self name:@"observe"];
  configuration.userContentController = controller;

  _webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:configuration];
  _webView.navigationDelegate = self;
  if (_url == NULL) {
    [_webView loadHTMLString:[self generateHomepage] baseURL:nil];
  }
  else {
    [_webView loadRequest:[[NSURLRequest alloc] initWithURL:_url]];
  }

  [self.view addSubview:_webView];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        _webView.frame = self.view.frame;
    } completion:nil];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSArray *contents = [message.body componentsSeparatedByString:@"~"];
    NSString *destination = (NSString *)contents[0];
    NSString *action = contents[1];

    NSLog(@"[AUPM] Web message %@", contents);

    if ([destination isEqual:@"local"]) {
      if ([action isEqual:@"nuke"]) {
        [self nukeDatabase];
      }
      else if ([action isEqual:@"sendBug"]) {
        [self sendBugReport];
      }
    }
    else if ([destination isEqual:@"web"]) {
      AUPMWebViewController *webViewController = [[AUPMWebViewController alloc] initWithURL:[NSURL URLWithString:action]];
      [[self navigationController] pushViewController:webViewController animated:true];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
  [self.navigationItem setTitle:[webView title]];
}

- (NSString *)generateHomepage {
	NSError *error;
	NSString *rawDepiction = [NSString stringWithContentsOfFile:@"/Applications/AUPM.app/home.html" encoding:NSUTF8StringEncoding error:&error];
	if (error != nil) {
		HBLogError(@"Error reading file: %@", error);
	}

	NSString *html = [NSString stringWithFormat:rawDepiction, PACKAGE_VERSION];

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
    NSString *message = [NSString stringWithFormat:@"iOS Version: %@\nAUPM Version: %@\nAUPM Database Location: %@\n\nPlease describe the bug you are experiencing or feature you are requesting below: \n\n", iosVersion, PACKAGE_VERSION, databaseLocation];

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
