#import "AUPMTabBarController.h"

#import "Repos/AUPMRepoListViewController.h"
#import "Packages/AUPMPackageListViewController.h"
#import "Search/AUPMSearchViewController.h"
#import "Database/AUPMDatabaseManager.h"

#import "AUPMAppDelegate.h"
#import "AUPMWebViewController.h"

@implementation AUPMTabBarController

- (void)loadView {
  [super loadView];

  UINavigationController *debugNavController = [[UINavigationController alloc] initWithRootViewController:[[AUPMWebViewController alloc] init]];
  UITabBarItem *debugIcon = [[UITabBarItem alloc] initWithTitle:@"Beta" image:[UIImage imageNamed:@"Beta.png"] selectedImage:[UIImage imageNamed:@"Beta.png"]];
  [debugNavController setTabBarItem:debugIcon];

  UINavigationController *reposNavController = [[UINavigationController alloc] initWithRootViewController:[[AUPMRepoListViewController alloc] init]];
  UITabBarItem *repoIcon = [[UITabBarItem alloc] initWithTitle:@"Sources" image:[UIImage imageNamed:@"Sources.png"] selectedImage:[UIImage imageNamed:@"Sources.png"]];
  [reposNavController setTabBarItem:repoIcon];

  UINavigationController *packagesNavController = [[UINavigationController alloc] initWithRootViewController:[[AUPMPackageListViewController alloc] init]];
  UITabBarItem *packageIcon = [[UITabBarItem alloc] initWithTitle:@"Packages" image:[UIImage imageNamed:@"Packages.png"] selectedImage:[UIImage imageNamed:@"Packages.png"]];
  [packagesNavController setTabBarItem:packageIcon];

  UINavigationController *searchNavController = [[UINavigationController alloc] initWithRootViewController:[[AUPMSearchViewController alloc] init]];
  UITabBarItem *searchIcon = [[UITabBarItem alloc] initWithTitle:@"Search" image:[UIImage imageNamed:@"Search.png"] selectedImage:[UIImage imageNamed:@"Search.png"]];
  [searchNavController setTabBarItem:searchIcon];

  self.viewControllers = [NSArray arrayWithObjects:debugNavController, reposNavController, packagesNavController, searchNavController, nil];

  [self performBackgroundRefresh:false];
}

// - (void)viewDidAppear:(BOOL)animated {
//   [super viewDidAppear:animated];
//
//   NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
//   NSString *cacheDirectory = [paths objectAtIndex:0];
//
//   UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Cache Directory"
//                            message:cacheDirectory
//                            preferredStyle:UIAlertControllerStyleAlert];
//
//   UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
//                                  handler:^(UIAlertAction * action) {}];
//
//   [alert addAction:defaultAction];
//   [self presentViewController:alert animated:YES completion:nil];
// }

- (void)performBackgroundRefresh:(BOOL)requested {
  BOOL timePassed;

  if (!requested) {
    NSDate *currentDate = [NSDate date];
    NSDate *lastUpdatedDate = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:@"lastUpdatedDate"];

    if (lastUpdatedDate != nil) {
      NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
      NSUInteger unitFlags = NSCalendarUnitMinute;
      NSDateComponents *components = [gregorian components:unitFlags fromDate:lastUpdatedDate toDate:currentDate options:0];

      timePassed = ([components minute] >= 30); //might need to be less
    }
    else {
      timePassed = true;
    }
  }

  if (requested || timePassed) {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
      UINavigationController *sourcesController = self.viewControllers[1];
      [sourcesController tabBarItem].badgeValue = @"⏳";
      AUPMDatabaseManager *databaseManager = ((AUPMAppDelegate *)[[UIApplication sharedApplication] delegate]).databaseManager;
      [databaseManager updatePopulation:^(BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self updatePackageTableView];
          [sourcesController tabBarItem].badgeValue = nil;
        });
      }];
    });
  }
  else {
    AUPMDatabaseManager *databaseManager = ((AUPMAppDelegate *)[[UIApplication sharedApplication] delegate]).databaseManager;
    [databaseManager updateEssentials:^(BOOL success) {
      if (success) {
        [self updatePackageTableView];
      }
    }];
  }
}

- (void)updatePackageTableView {
  UINavigationController *packageNavController = self.viewControllers[2];
  AUPMPackageListViewController *packageVC = packageNavController.viewControllers[0];
  AUPMDatabaseManager *databaseManager = ((AUPMAppDelegate *)[[UIApplication sharedApplication] delegate]).databaseManager;
  if ([databaseManager hasPackagesThatNeedUpdates]) {
    [packageNavController tabBarItem].badgeValue = [NSString stringWithFormat:@"%lu", (unsigned long)[databaseManager numberOfPackagesThatNeedUpdates]];
    [packageVC refreshTable];
  }
  else {
    [packageNavController tabBarItem].badgeValue = nil;
    [packageVC refreshTable];
  }
}

@end
