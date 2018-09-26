#import "AUPMAppDelegate.h"
#import "Repos/AUPMRepoListViewController.h"
#import "Packages/AUPMPackageListViewController.h"
#import "AUPMRefreshViewController.h"
#import "AUPMDatabaseManager.h"
#import "AUPMTabBarController.h"
#import "NSTask.h"
#import <Realm/Realm.h>

@implementation AUPMAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	NSLog(@"[AUPM] AUPM Version %@", PACKAGE_VERSION);
	self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.window.backgroundColor = [UIColor whiteColor]; //Fixes a weird visual issue after pushing a vc
	self.window.tintColor = [UIColor colorWithRed:0.00 green:0.66 blue:1.00 alpha:1.0];

	RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = paths[0];
	NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/AUPMDatabase"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])
    [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:nil];
	config.fileURL = [NSURL URLWithString:[dataPath stringByAppendingPathComponent:@"/aupm.realm"]];
	config.deleteRealmIfMigrationNeeded = YES;
	[RLMRealmConfiguration setDefaultConfiguration:config];

	self.databaseManager = [[AUPMDatabaseManager alloc] init];

	if ([[RLMRealm defaultRealm] isEmpty]) {

		NSTask *cpTask = [[NSTask alloc] init];
	  [cpTask setLaunchPath:@"/Applications/AUPM.app/supersling"];
	  NSArray *cpArgs = [[NSArray alloc] initWithObjects: @"cp", @"-fR", @"/var/lib/aupm/default.list", @"/var/lib/aupm/aupm.list", nil];
	  [cpTask setArguments:cpArgs];

	  [cpTask launch];
	  [cpTask waitUntilExit];

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
