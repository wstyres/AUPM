#import "AUPMAppDelegate.h"
#import "Repos/AUPMRepoListViewController.h"
#import "Packages/AUPMPackageListViewController.h"
#import "AUPMRefreshViewController.h"
#import "AUPMDatabaseManager.h"
#import "AUPMTabBarController.h"
#import "NSTask.h"
#import <Realm/Realm.h>

@implementation AUPMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	NSLog(@"[AUPM] AUPM Version %@", PACKAGE_VERSION);
	self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.window.backgroundColor = [UIColor whiteColor]; //Fixes a weird visual issue after pushing a vc
	self.window.tintColor = [UIColor colorWithRed:0.62 green:0.67 blue:0.90 alpha:1.0];

#ifdef TARGET_IPHONE_SIMULATOR
	NSLog(@"[AUPM] Wake up, neo...");
	RLMRealm *realm = [RLMRealm defaultRealm];
#else
	NSLog(@"[AUPM] I'm a real boy!");
	RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];

	config.fileURL = [NSURL URLWithString:@"/var/lib/aupm/database/aupm.realm"];
	config.deleteRealmIfMigrationNeeded = YES;
	[RLMRealmConfiguration setDefaultConfiguration:config];

	self.databaseManager = [[AUPMDatabaseManager alloc] init];

	if (![[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/aupm/aupm.list"]) {
		NSTask *cpTask = [[NSTask alloc] init];
		[cpTask setLaunchPath:@"/Applications/AUPM.app/supersling"];
		NSArray *cpArgs;

		if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0")) {
			if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Applcations/electra1131.app"] || [[NSFileManager defaultManager] fileExistsAtPath:@"/Applcations/Electra.app"]) {
				NSLog(@"[AUPM] Electra detected, installing electra repos");

				cpArgs = [[NSArray alloc] initWithObjects: @"cp", @"-fR", @"/var/lib/aupm/default-electra.list", @"/var/lib/aupm/aupm.list", nil];
			}
			else if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Applcations/Undecimus.app"]) {
				NSLog(@"[AUPM] unc0ver detected, installing unc0ver repos");

				cpArgs = [[NSArray alloc] initWithObjects: @"cp", @"-fR", @"/var/lib/aupm/default-uncover.list", @"/var/lib/aupm/aupm.list", nil];
			}
		}
		else {
			NSLog(@"[AUPM] System version is less that 11.0, installing Cydia's repo");

			cpArgs = [[NSArray alloc] initWithObjects: @"cp", @"-fR", @"/var/lib/aupm/default.list", @"/var/lib/aupm/aupm.list", nil];
		}

		[cpTask setArguments:cpArgs];

		[cpTask launch];
		[cpTask waitUntilExit];
	}

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
	return 0;
}

@end
