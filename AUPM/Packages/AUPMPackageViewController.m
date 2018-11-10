#import "AUPMPackageViewController.h"

#import "Console/AUPMConsoleViewController.h"
#import "Queue/AUPMQueue.h"
#import "Queue/AUPMQueueAction.h"
#import "Queue/AUPMQueueViewController.h"
#import <MobileGestalt/MobileGestalt.h>
#import <sys/sysctl.h>

#import "AUPMPackage.h"
#import "AUPMWebViewController.h"

@interface AUPMPackageViewController () {
	BOOL _isFinishedLoading;
	WKWebView *_webView;
	AUPMPackage *_package;
	UIProgressView *_progressView;
	NSTimer *_progressTimer;
	BOOL loadFailed;
}

@end

@implementation AUPMPackageViewController

- (id)initWithPackage:(AUPMPackage *)package {
	_package = package;

	return self;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[self configureNavButton];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	[self.view setBackgroundColor:[UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0]];

	WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
	configuration.applicationNameForUserAgent = [NSString stringWithFormat:@"AUPM/%@ (Cydia)", PACKAGE_VERSION];

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
	[_webView setNavigationDelegate:self];

	NSURL *url = [[NSBundle mainBundle] URLForResource:@"package_depiction" withExtension:@".html" subdirectory:@"html"];
	[_webView loadFileURL:url allowingReadAccessToURL:[url URLByDeletingLastPathComponent]];

	self.title = [_package packageName];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
	NSURLRequest *request = [navigationAction request];
	NSURL *url = [request URL];

	int type = navigationAction.navigationType;
	NSLog(@"[AUPM] Navigation Type %d", type);

	if ([navigationAction.request.URL isFileURL] || (type == -1 && [navigationAction.request.URL isEqual:[NSURL URLWithString:[_package depictionURL]]])) {
		decisionHandler(WKNavigationActionPolicyAllow);
	}
	else if (![navigationAction.request.URL isEqual:[NSURL URLWithString:@"about:blank"]]) {
		if (type != -1) {
			NSLog(@"[AUPM] %@", navigationAction.request.URL);
			AUPMWebViewController *webViewController = [[AUPMWebViewController alloc] initWithURL:url];
			[[self navigationController] pushViewController:webViewController animated:true];
			decisionHandler(WKNavigationActionPolicyCancel);
		}
		else {
			decisionHandler(WKNavigationActionPolicyAllow);
		}
	}
	else {
		decisionHandler(WKNavigationActionPolicyCancel);
	}
}

- (void)configureNavButton {
	if ([_package isInvalidated]) {
		NSLog(@"[AUPM] Object Invalidated!");
		[[self navigationController] popViewControllerAnimated:true];
	}
	else {
		if ([_package isInstalled]) {
			if ([_package isFromRepo]) {
				UIBarButtonItem *removeButton = [[UIBarButtonItem alloc] initWithTitle:@"Modify" style:UIBarButtonItemStylePlain target:self action:@selector(modifyPackage)];
				self.navigationItem.rightBarButtonItem = removeButton;
			}
			else {
				UIBarButtonItem *removeButton = [[UIBarButtonItem alloc] initWithTitle:@"Remove" style:UIBarButtonItemStylePlain target:self action:@selector(removePackage)];
				self.navigationItem.rightBarButtonItem = removeButton;
			}
		}
		else {
			UIBarButtonItem *installButton = [[UIBarButtonItem alloc] initWithTitle:@"Install" style:UIBarButtonItemStylePlain target:self action:@selector(installPackage)];
			self.navigationItem.rightBarButtonItem = installButton;
		}
	}
}

- (void)modifyPackage {
	UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

	UIAlertAction *removeAction = [UIAlertAction actionWithTitle:@"Remove" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
		[alert dismissViewControllerAnimated:true completion:nil];

		AUPMQueue *queue = [AUPMQueue sharedInstance];
		[queue addPackage:self->_package toQueueWithAction:AUPMQueueActionRemove];

		AUPMQueueViewController *queueVC = [[AUPMQueueViewController alloc] init];
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:queueVC];
		[self presentViewController:navController animated:true completion:nil];
	}];

	UIAlertAction *reinstallAction = [UIAlertAction actionWithTitle:@"Reinstall" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
		[alert dismissViewControllerAnimated:true completion:nil];

		AUPMQueue *queue = [AUPMQueue sharedInstance];
		[queue addPackage:self->_package toQueueWithAction:AUPMQueueActionReinstall];

		AUPMQueueViewController *queueVC = [[AUPMQueueViewController alloc] init];
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:queueVC];
		[self presentViewController:navController animated:true completion:nil];
	}];

	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
		[alert dismissViewControllerAnimated:true completion:nil];
	}];

	[alert addAction:removeAction];
	[alert addAction:reinstallAction];
	[alert addAction:cancelAction];
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)installPackage {
	AUPMQueue *queue = [AUPMQueue sharedInstance];
	[queue addPackage:_package toQueueWithAction:AUPMQueueActionInstall];

	AUPMQueueViewController *queueVC = [[AUPMQueueViewController alloc] init];
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:queueVC];
	[self presentViewController:navController animated:true completion:nil];
}

- (void)removePackage {
	AUPMQueue *queue = [AUPMQueue sharedInstance];
	[queue addPackage:_package toQueueWithAction:AUPMQueueActionRemove];

	AUPMQueueViewController *queueVC = [[AUPMQueueViewController alloc] init];
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:queueVC];
	[self presentViewController:navController animated:true completion:nil];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
	[_progressTimer invalidate];
	_progressView.hidden = false;
	_progressView.alpha = 1.0;
	_progressView.progress = 0;
	_progressView.trackTintColor = [UIColor clearColor];
	_isFinishedLoading = false;
	_progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.01667 target:self selector:@selector(refreshProgress) userInfo:nil repeats:YES];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
	_isFinishedLoading = TRUE;

	NSURL *depictionURL = [NSURL URLWithString:[_package depictionURL]];

	[_webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('package').innerHTML = '%@ (%@)';", [_package packageName], [_package packageIdentifier]] completionHandler:nil];
	[_webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('version').innerHTML = 'Version %@';", [_package version]] completionHandler:nil];

	NSLog(@"%@", [_package packageDescription]);
	if ([_package packageDescription] == NULL || [[_package packageDescription] isEqual:@""] || [_package depictionURL] != NULL)  {
		[_webView evaluateJavaScript:@"var element = document.getElementById('desc-holder').outerHTML = '';" completionHandler:nil];
		[_webView evaluateJavaScript:@"var element = document.getElementById('main-holder').style.marginBottom = '0px';" completionHandler:nil];
		NSString *command = [NSString stringWithFormat:@"document.getElementById('depiction-src').src = '%@';", [depictionURL absoluteString]];
		[_webView evaluateJavaScript:command completionHandler:nil];
	}
	else {
		[_webView evaluateJavaScript:@"var element = document.getElementById('depiction-src').outerHTML = '';" completionHandler:nil];
		[_webView evaluateJavaScript:[NSString stringWithFormat:@"document.getElementById('desc').innerHTML = \"%@\";", [_package packageDescription]] completionHandler:nil];
	}
}

-(void)refreshProgress {
	if (_isFinishedLoading) {
		if (_progressView.progress >= 1) {
			[UIView animateWithDuration:0.3 delay:0.3 options:0 animations:^{
				self->_progressView.alpha = 0.0;
			} completion:^(BOOL finished) {
				[self->_progressTimer invalidate];
				self->_progressTimer = nil;
			}];
		}
		else {
			_progressView.progress += 0.1;
		}
	}
	else {
		if (_progressView.progress >= _webView.estimatedProgress) {
			_progressView.progress = _webView.estimatedProgress;
		}
		else {
			_progressView.progress += 0.005;
		}

		if (_progressView.progress == 1.0) {
			loadFailed = true;
			NSURL *url = [[NSBundle mainBundle] URLForResource:@"package_depiction" withExtension:@".html" subdirectory:@"html"];
			[_webView loadFileURL:url allowingReadAccessToURL:[url URLByDeletingLastPathComponent]];
		}
	}
}

@end
