#import "AUPMAppDelegate.h"
#import "Repos/AUPMRepoListViewController.h"
#import "Packages/AUPMPackageListViewController.h"
#import "AUPMRefreshViewController.h"
#import "AUPMDatabaseManager.h"
#import "AUPMTabBarController.h"
#import <Realm/Realm.h>

@implementation AUPMAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.window.backgroundColor = [UIColor whiteColor]; //Fixes a weird visual issue after pushing a vc

	self.databaseManager = [[AUPMDatabaseManager alloc] init];

	if ([[RLMRealm defaultRealm] isEmpty]) {
		AUPMRefreshViewController *refreshViewController = [[AUPMRefreshViewController alloc] init];

		self.window.rootViewController = refreshViewController;
	}
	else {
		AUPMTabBarController *tabBarController = [[AUPMTabBarController alloc] init];

		self.window.rootViewController = tabBarController;
	}

	[self.window makeKeyAndVisible];
}

@end
