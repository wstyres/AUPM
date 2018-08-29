#import "AUPMTabBarController.h"
#import "Repos/AUPMRepoListViewController.h"
#import "Packages/AUPMPackageListViewController.h"
#import "AUPMDebugViewController.h"
#import "AUPMDatabaseManager.h"

@implementation AUPMTabBarController

- (id)init {
  self = [super init];
  if (self) {
    _databaseManager = [[AUPMDatabaseManager alloc] init];
  }
  return self;
}

- (AUPMDatabaseManager *)databaseManager {
  return _databaseManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];

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
}

@end
