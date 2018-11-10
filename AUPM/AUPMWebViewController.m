#import "AUPMWebViewController.h"

#import "Database/AUPMRefreshViewController.h"
#import "Repos/AUPMRepoManager.h"

@interface AUPMWebViewController () {
  WKWebView *_webView;
  UIProgressView *_progressView;
  NSURL *_url;
}
@end

@implementation AUPMWebViewController

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

- (void)viewDidLoad {
  [super viewDidLoad];

  [self.view setBackgroundColor:[UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0]];

  WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
  configuration.applicationNameForUserAgent = [NSString stringWithFormat:@"AUPM/%@", PACKAGE_VERSION];

  WKUserContentController *controller = [[WKUserContentController alloc] init];
  [controller addScriptMessageHandler:self name:@"observe"];
  configuration.userContentController = controller;

  _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0,0,0,0) configuration:configuration];
  _webView.translatesAutoresizingMaskIntoConstraints = NO;

  [self.view addSubview:_webView];

  _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0,0,0,0)];
  _progressView.translatesAutoresizingMaskIntoConstraints = NO;

  [_webView addSubview:_progressView];

  //Web View Layout

  NSLayoutConstraint *webTop = [NSLayoutConstraint constraintWithItem:_webView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:0.f];
  NSLayoutConstraint *webLeading = [NSLayoutConstraint constraintWithItem:_webView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1 constant:0.f];
  NSLayoutConstraint *webBottom = [NSLayoutConstraint constraintWithItem:_webView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomLayoutGuide attribute:NSLayoutAttributeTop multiplier:1 constant:0.f];
  NSLayoutConstraint *webTrailing = [NSLayoutConstraint constraintWithItem:_webView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:0.f];

  [self.view addConstraints:@[webTop, webLeading, webBottom, webTrailing]];

  //Progress View Layout

  NSLayoutConstraint *progressTrailing = [NSLayoutConstraint constraintWithItem:_webView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:_progressView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0.f];
  NSLayoutConstraint *progressLeading = [NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:_webView attribute:NSLayoutAttributeLeading multiplier:1 constant:0.f];
  NSLayoutConstraint *progressTop = [NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_webView attribute:NSLayoutAttributeTop multiplier:1 constant:0.f];

  [_webView addConstraints:@[progressTrailing, progressLeading, progressTop]];

  _webView.navigationDelegate = self;
  _webView.opaque = false;
  _webView.backgroundColor = [UIColor clearColor];

  if (_url == NULL) {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"home" withExtension:@".html" subdirectory:@"html"];
    [_webView loadFileURL:url allowingReadAccessToURL:[url URLByDeletingLastPathComponent]];
  }
  else {
    [_webView loadRequest:[[NSURLRequest alloc] initWithURL:_url]];
  }

  [_webView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:NSKeyValueObservingOptionNew context:NULL];

  UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)];
  self.navigationItem.rightBarButtonItem = refreshButton;
}

- (void)refresh {
  [_webView reload];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == _webView) {
    [_progressView setAlpha:1.0f];
    [_progressView setProgress:_webView.estimatedProgress animated:YES];

    if (_webView.estimatedProgress >= 1.0f) {
      [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self->_progressView setAlpha:0.0f];
      } completion:^(BOOL finished) {
        [self->_progressView setProgress:0.0f animated:NO];
      }];
    }
  }
  else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
  NSArray *contents = [message.body componentsSeparatedByString:@"~"];
  NSString *destination = (NSString *)contents[0];
  NSString *action = contents[1];

  if ([destination isEqual:@"local"]) {
    if ([action isEqual:@"nuke"]) {
      [self nukeDatabase];
    }
    else if ([action isEqual:@"sendBug"]) {
      [self sendBugReport];
    }
  }
  else if ([destination isEqual:@"web"]) {
    AUPMWebViewController *_webViewController = [[AUPMWebViewController alloc] initWithURL:[NSURL URLWithString:action]];
    [[self navigationController] pushViewController:_webViewController animated:true];
  }
  else if ([destination isEqual:@"repo"]) {
    [self handleRepoAdd:action local:false];
  }
  else if ([destination isEqual:@"repo-local"]) {
    [self handleRepoAdd:action local:true];
  }
}

- (void)handleRepoAdd:(NSString *)repo local:(BOOL)local {
  NSLog(@"[AUPM] Handling repo add");
  AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];
  if (local) {
    NSArray *options = @[
  		@"transfer",
  		@"cydia",
  		@"electra",
  		@"uncover",
      @"bigboss",
      @"modmyi",
    ];

    switch ([options indexOfObject:repo]) {
      case 0:
        NSLog(@"[AUPM] Transferring Sources from Cydia");
        break;
      case 1:
        [repoManager addDebLine:@"deb http://apt.saurik.com/ ios/1349.70 main\n"];
        break;
      case 2:
        [repoManager addDebLine:@"deb https://electrarepo64.coolstar.org/ ./\ndeb https://electrarepo64.coolstar.org/substrate-shim/ ./\n"];
        break;
      case 3:
        [repoManager addDebLine:@"deb http://repo.bingner.com/ ./\n"];
        break;
      case 4:
        [repoManager addDebLine:@"deb http://apt.thebigboss.org/repofiles/cydia/ stable main\n"];
        break;
      case 5:
        [repoManager addDebLine:@"deb http://apt.modmyi.com/ stable main\n"];
        break;
      default:
        return;
    }

    AUPMRefreshViewController *refreshViewController = [[AUPMRefreshViewController alloc] initWithAction:1];
		[self presentViewController:refreshViewController animated:true completion:nil];
  }
  else {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Are you sure?" message:@"Are you sure you want to add this repo?" preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Do it." style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
      [repoManager addSourceWithURL:repo response:^(BOOL success, NSString *error, NSURL *url) {
        if (!success) {
          NSLog(@"[AUPM] Could not add source %@ due to error %@", url.absoluteString, error);
        }
        else {
          NSLog(@"[AUPM] Added source.");
          AUPMRefreshViewController *refreshViewController = [[AUPMRefreshViewController alloc] initWithAction:1];
          [self presentViewController:refreshViewController animated:true completion:nil];
        }
      }];
    }];

    UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No way!" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
      [alert dismissViewControllerAnimated:true completion:nil];
    }];

    [alert addAction:yesAction];
    [alert addAction:noAction];

    [self presentViewController:alert animated:YES completion:nil];
  }
}

- (void)presentVerificationFailedAlert:(NSString *)message url:(NSURL *)url {
	dispatch_async(dispatch_get_main_queue(), ^{
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Unable to verify Repo" message:message preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
			[alertController dismissViewControllerAnimated:true completion:nil];
		}];
		[alertController addAction:okAction];

		[self presentViewController:alertController animated:true completion:nil];
	});
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
  [self.navigationItem setTitle:[webView title]];
  if (_url == NULL) {
#if TARGET_OS_SIMULATOR
    [webView evaluateJavaScript:@"document.getElementById('neo').innerHTML = 'Wake up, Neo...'" completionHandler:nil];
#else
    [webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('neo').innerHTML = \"You are running AUPM Version %@\"", PACKAGE_VERSION] completionHandler:nil];
#endif
  }
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
