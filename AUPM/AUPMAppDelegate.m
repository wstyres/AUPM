#import "AUPMAppDelegate.h"

#import "Repos/AUPMRepoListViewController.h"
#import "Packages/AUPMPackageListViewController.h"
#import "Database/AUPMRefreshViewController.h"
#import "Database/AUPMDatabaseManager.h"

#import "AUPMTabBarController.h"
#import "NSTask.h"

@implementation AUPMAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	NSLog(@"[AUPM] AUPM Version %@", PACKAGE_VERSION);
	self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.window.backgroundColor = [UIColor whiteColor]; //Fixes a weird visual issue after pushing a vc
	self.window.tintColor = [UIColor colorWithRed:0.62 green:0.67 blue:0.90 alpha:1.0];

	self.databaseManager = [[AUPMDatabaseManager alloc] init];

#if TARGET_OS_SIMULATOR
	NSLog(@"[AUPM] Wake up, neo...");
	RLMRealm *realm = [RLMRealm defaultRealm];
#else
	NSLog(@"[AUPM] I'm a real boy!");
	RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];

	config.fileURL = [NSURL URLWithString:@"/var/lib/aupm/database/aupm.realm"];
	config.deleteRealmIfMigrationNeeded = YES;
	[RLMRealmConfiguration setDefaultConfiguration:config];

	NSError *configError;
	RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:&configError];

	if (configError != nil) {
		NSLog(@"[AUPM] Error when opening database: %@", configError.localizedDescription);
	}
#endif

	if ([realm isEmpty]) {
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
