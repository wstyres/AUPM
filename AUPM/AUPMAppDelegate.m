#import "AUPMAppDelegate.h"
#import "AUPMDatabaseManager.h"
#import "Repos/AUPMRepoListViewController.h"
#import "Packages/AUPMPackageListViewController.h"
#import "AUPMRefreshViewController.h"

@implementation AUPMAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.window.backgroundColor = [UIColor whiteColor]; //Fixes a weird visual issue after pushing a vc

	self.databaseManager = [[AUPMDatabaseManager alloc] init];

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"firstSetupComplete"]) {
		AUPMRefreshViewController *refreshViewController = [[AUPMRefreshViewController alloc] initWithAction:1];

		self.window.rootViewController = refreshViewController;
	}
	else {
		AUPMRefreshViewController *refreshViewController = [[AUPMRefreshViewController alloc] init];

		self.window.rootViewController = refreshViewController;
	}

	[self.window makeKeyAndVisible];
}

@end
