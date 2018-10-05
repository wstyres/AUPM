#import "AUPMPackageViewController.h"
#import "AUPMPackage.h"
#import "../AUPMConsoleViewController.h"
#import "../AUPMQueue.h"
#import "../AUPMQueueAction.h"
#import "AUPMQueueViewController.h"

@implementation AUPMPackageViewController {
	BOOL _isFinishedLoading;
	WKWebView *_webView;
	AUPMPackage *_package;
	UIProgressView *_progressBar;
	NSTimer *_progressTimer;
}

- (id)initWithPackage:(AUPMPackage *)package {
	_package = package;

	return self;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[self configureNavButton];
}

- (void)loadView {
	[super loadView];

	[self.view setBackgroundColor:[UIColor whiteColor]]; //Fixes a weird animation issue when pushing
	CGFloat height = [[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height + self.tabBarController.tabBar.frame.size.height;
	_webView = [[WKWebView alloc] initWithFrame:CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height - height)];
	[_webView setNavigationDelegate:self];
	NSURL *depictionURL = [NSURL URLWithString: [_package depictionURL]];
	if (depictionURL != NULL) {
		[_webView loadRequest:[[NSURLRequest alloc] initWithURL:depictionURL]];
	}
	else {
		[_webView loadHTMLString:[self generateDepiction] baseURL:nil];
	}
	_webView.allowsBackForwardNavigationGestures = true;
	_progressBar = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 9)];
	[_webView addSubview:_progressBar];
	[self.view addSubview:_webView];

	self.title = [_package packageName];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        _webView.frame = self.view.frame;
    } completion:nil];
}

- (NSString *)generateDepiction {
	NSError *error;
	NSString *rawDepiction = [NSString stringWithContentsOfFile:@"/Applications/AUPM.app/package_depiction.html" encoding:NSUTF8StringEncoding error:&error];
	if (error != nil) {
		HBLogError(@"Error reading file: %@", error);
	}

	NSString *html = [NSString stringWithFormat:rawDepiction, [_package packageName], [_package packageName], [_package packageIdentifier], [_package version], [_package packageDescription]];

	return html;
}

- (void)configureNavButton {
	if ([_package isInvalidated]) {
    NSLog(@"[AUPM] Object Invalidated!");
		[[self navigationController] popViewControllerAnimated:true];
  }
	else {
		if ([_package isInstalled]) {
			UIBarButtonItem *removeButton = [[UIBarButtonItem alloc] initWithTitle:@"Remove" style:UIBarButtonItemStylePlain target:self action:@selector(removePackage)];
			self.navigationItem.rightBarButtonItem = removeButton;
		}
		else {
			UIBarButtonItem *installButton = [[UIBarButtonItem alloc] initWithTitle:@"Install" style:UIBarButtonItemStylePlain target:self action:@selector(installPackage)];
			self.navigationItem.rightBarButtonItem = installButton;
		}
	}
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
	_progressBar.hidden = false;
	_progressBar.alpha = 1.0;
	_progressBar.progress = 0;
	_progressBar.trackTintColor = [UIColor clearColor];
	_isFinishedLoading = false;
	_progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.01667 target:self selector:@selector(refreshProgress) userInfo:nil repeats:YES];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
	_isFinishedLoading = TRUE;
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

@end
