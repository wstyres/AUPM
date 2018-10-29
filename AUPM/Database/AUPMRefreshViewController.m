#import "AUPMRefreshViewController.h"

#import "Repos/AUPMRepoListViewController.h"
#import "Packages/AUPMPackageListViewController.h"

#import "AUPMAppDelegate.h"
#import "AUPMDatabaseManager.h"
#import "AUPMTabBarController.h"

@interface AUPMRefreshViewController () {
    BOOL _action;
}
@end

@implementation AUPMRefreshViewController

- (id)init {
    self = [super init];
    if (self) {
        _action = 0;
    }
    return self;
}

- (id)initWithAction:(int)action {
    self = [super init];
    if (self) {
        _action = action;
    }
    return self;
}

- (void)loadView {
    [super loadView];

    [self.view setBackgroundColor:[UIColor whiteColor]];

    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:activityIndicator];
    [activityIndicator startAnimating];
    activityIndicator.center = self.view.center;

    UILabel *statusLabel = [[UILabel alloc] init];
    statusLabel.text = @"Updating database...";
    [statusLabel sizeToFit];
    statusLabel.center = CGPointMake(self.view.center.x, self.view.center.y + 30);
    [self.view addSubview:statusLabel];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    AUPMDatabaseManager *databaseManager = ((AUPMAppDelegate *)[[UIApplication sharedApplication] delegate]).databaseManager;
    if (_action == 0) {
        NSDate *methodStart = [NSDate date];
        [databaseManager firstLoadPopulation:^(BOOL success) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstSetupComplete"];
            [[NSUserDefaults standardUserDefaults] synchronize];

            NSDate *methodFinish = [NSDate date];
            NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
            NSLog(@"[AUPM] Completed in %f seconds", executionTime);

            [self goAway];
        }];
    }
    else if (_action == 1) {
      NSDate *methodStart = [NSDate date];
      [databaseManager updatePopulation:^(BOOL success) {
        NSDate *methodFinish = [NSDate date];
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
        NSLog(@"[AUPM] Completed in %f seconds", executionTime);

        [self goAway];
      }];
    }
    else {
        HBLogInfo(@"Invalid action...");
        [self goAway];
    }
}

- (void)goAway {
    if ([self presentingViewController]) {
        [self dismissViewControllerAnimated:true completion:nil];
    }
    else {
        AUPMTabBarController *tabBarController = [[AUPMTabBarController alloc] init];

        [[UIApplication sharedApplication] keyWindow].rootViewController = tabBarController;
    }
}

@end