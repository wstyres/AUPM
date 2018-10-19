#import "AUPMWebViewController.h"
#import "AUPMRefreshViewController.h"
#import <Realm/Realm.h>

@implementation AUPMWebViewController {
  WKWebView *_webView;
  UIProgressView *_progressView;
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

  [_webView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:NSKeyValueObservingOptionNew context:NULL];

  _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0.0f, self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height, [[UIScreen mainScreen] bounds].size.width, 9)];
  [_webView addSubview:_progressView];

  [self.view addSubview:_webView];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == _webView) {
        [_progressView setAlpha:1.0f];
        [_progressView setProgress:_webView.estimatedProgress animated:YES];

        if(_webView.estimatedProgress >= 1.0f) {
            [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
                [_progressView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [_progressView setProgress:0.0f animated:NO];
            }];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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

  if (_url == NULL) {
    [_webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById(\"version\").innerHTML = \"You are running AUPM Version %@\"", PACKAGE_VERSION] completionHandler:nil];
  }
}

- (NSString *)generateHomepage {
	NSError *error;
	NSString *rawDepiction = [NSString stringWithContentsOfFile:@"/Applications/AUPM.app/home.html" encoding:NSUTF8StringEncoding error:&error];
	if (error != nil) {
		HBLogError(@"Error reading file: %@", error);
	}

	return rawDepiction;
}

- (void)nukeDatabase {
  AUPMRefreshViewController *refreshViewController = [[AUPMRefreshViewController alloc] init];

  [[UIApplication sharedApplication] keyWindow].rootViewController = refreshViewController;
}

- (void)sendBugReport {
  if ([MFMailComposeViewController canSendMail]) {
    NSString *iosVersion = [NSString stringWithFormat:@"%@ running iOS %@", [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion]];
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
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
