#import "AUPMTabBarController.h"
#import "Repos/AUPMRepoListViewController.h"
#import "Packages/AUPMPackageListViewController.h"
#import "AUPMDebugViewController.h"
#import "AUPMDatabaseManager.h"
#import "AUPMAppDelegate.h"

@implementation AUPMTabBarController

- (void)loadView {
  [super loadView];

  UINavigationController *reposNavController = [[UINavigationController alloc] initWithRootViewController:[[AUPMRepoListViewController alloc] init]];
  UITabBarItem *repoIcon = [[UITabBarItem alloc] initWithTitle:@"Sources" image:[UIImage imageNamed:@"sources.png"] selectedImage:[UIImage imageNamed:@"sources-filled.png"]];
  [reposNavController setTabBarItem:repoIcon];

  UINavigationController *packagesNavController = [[UINavigationController alloc] initWithRootViewController:[[AUPMPackageListViewController alloc] init]];
  UITabBarItem *packageIcon = [[UITabBarItem alloc] initWithTitle:@"Packages" image:[UIImage imageNamed:@"installed.png"] selectedImage:[UIImage imageNamed:@"installed-filled.png"]];
  [packagesNavController setTabBarItem:packageIcon];

  UINavigationController *debugNavController = [[UINavigationController alloc] initWithRootViewController:[[AUPMDebugViewController alloc] init]];
  UITabBarItem *debugIcon = [[UITabBarItem alloc] initWithTitle:@"Nuke" image:[UIImage imageNamed:@"debug.png"] selectedImage:[UIImage imageNamed:@"debug-filled.png"]];
  [debugNavController setTabBarItem:debugIcon];

  self.viewControllers = [NSArray arrayWithObjects:reposNavController, packagesNavController, debugNavController, nil];

  [self performBackgroundRefresh:false];
}

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
      UINavigationController *sourcesController = self.viewControllers[0];
      [sourcesController tabBarItem].badgeValue = @"⏳";
      AUPMDatabaseManager *databaseManager = ((AUPMAppDelegate *)[[UIApplication sharedApplication] delegate]).databaseManager;
      [databaseManager updatePopulation:^(BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [sourcesController tabBarItem].badgeValue = nil;
        });
      }];
    });
  }
}

@end
