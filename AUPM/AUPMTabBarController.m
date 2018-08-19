#import "AUPMTabBarController.h"
#import "Repos/AUPMRepoListViewController.h"
#import "Packages/AUPMPackageListViewController.h"

@implementation AUPMTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];

    UINavigationController *reposNavController = [[UINavigationController alloc] initWithRootViewController:[[AUPMRepoListViewController alloc] init]];
    UITabBarItem *repoIcon = [[UITabBarItem alloc] initWithTitle:@"Sources" image:[UIImage imageNamed:@"sources.png"] selectedImage:[UIImage imageNamed:@"sources-filled.png"]];
    [reposNavController setTabBarItem:repoIcon];

    UINavigationController *packagesNavController = [[UINavigationController alloc] initWithRootViewController:[[AUPMPackageListViewController alloc] init]];
    UITabBarItem *packageIcon = [[UITabBarItem alloc] initWithTitle:@"Packages" image:[UIImage imageNamed:@"installed.png"] selectedImage:[UIImage imageNamed:@"installed-filled.png"]];
    [packagesNavController setTabBarItem:packageIcon];

    self.viewControllers = [NSArray arrayWithObjects:reposNavController, packagesNavController,nil];
}

@end
