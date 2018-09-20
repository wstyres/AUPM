#import "AUPMDebugViewController.h"
#import "AUPMRefreshViewController.h"

@implementation AUPMDebugViewController {
  BOOL _isFinishedLoading;
  WKWebView *_webView;
  UIProgressView *_progressBar;
  NSTimer *_progressTimer;
}

- (void)loadView {
  [super loadView];

  [self.view setBackgroundColor:[UIColor whiteColor]]; //Fixes a weird animation issue when pushing
  CGFloat height = [[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height + self.tabBarController.tabBar.frame.size.height;
  _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height - height)];
  [_webView setNavigationDelegate:self];
  NSURL *url = [NSURL URLWithString:@"https://xtm3x.github.io/aupm/"];
  [_webView loadRequest:[[NSURLRequest alloc] initWithURL:url]];
  _progressBar = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 9)];
  [_webView addSubview:_progressBar];
  [self.view addSubview:_webView];

  self.title = @"AUPM Beta";
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

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  if ([[[request URL] absoluteString] hasPrefix:@"ios:"]) {
    NSArray *strArr = [[[request URL] absoluteString] componentsSeparatedByString:@":"];
    NSString *action = strArr[1];
    if ([action isEqualToString:@"nuke"]) {
      [self nukeDatabase];
    }
    else if ([action isEqualToString:@"sendBug"]) {
      [self sendBugReport];
    }
  }
  return YES;
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
  [_progressTimer invalidate];
  _progressBar.hidden = false;
  _progressBar.alpha = 1.0;
  _progressBar.progress = 0;
  _progressBar.trackTintColor = [UIColor clearColor];
  _isFinishedLoading = false;
  _progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.01667 target:self selector:@selector(refreshProgress) userInfo:nil repeats:YES];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
  _isFinishedLoading = TRUE;

  [webView evaluateJavaScript:@"document.documentElement.outerHTML.toString()" completionHandler:^(id html, NSError *error) {
    NSString *modififedHTML = [NSString stringWithFormat:(NSString *)html, @"1.0~beta1"];
    [_webView loadHTMLString:modififedHTML baseURL:nil];
  }];
}

-(void)refreshProgress {
  if (_isFinishedLoading) {
    if (_progressBar.progress >= 1) {
      [UIView animateWithDuration:0.3 delay:0.3 options:0 animations:^{
        _progressBar.alpha = 0.0;
      } completion:^(BOOL finished) {
        [_progressTimer invalidate];
        _progressTimer = nil;
      }];
    }
    else {
      _progressBar.progress += 0.1;
    }
  }
  else {
    if (_progressBar.progress >= _webView.estimatedProgress) {
      _progressBar.progress = _webView.estimatedProgress;
    }
    else {
      _progressBar.progress += 0.005;
    }
  }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
