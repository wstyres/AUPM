#import "AUPMRefreshViewController.h"

#import "Repos/AUPMRepoListViewController.h"
#import "Packages/AUPMPackageListViewController.h"

#import "AUPMAppDelegate.h"
#import "AUPMDatabaseManager.h"
#import "AUPMTabBarController.h"
#import "NSTask.h"

@interface AUPMRefreshViewController () {
    BOOL _action;
    NSArray *_pickedArgs;
}
@end

@implementation AUPMRefreshViewController

CFArrayRef SBSCopyApplicationDisplayIdentifiers(bool onlyActive, bool debuggable);

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

    NSLog(@"[AUPM] Starting refresh");

    AUPMDatabaseManager *databaseManager = ((AUPMAppDelegate *)[[UIApplication sharedApplication] delegate]).databaseManager;
    if (_action == 0) {
#if TARGET_CPU_ARM
      if (![[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/aupm/aupm.list"]) {
        [self createList];
      }
#endif


      NSLog(@"[AUPM] Full refresh");
        NSDate *methodStart = [NSDate date];
        [databaseManager firstLoadPopulation:^(BOOL success) {
          NSLog(@"[AUPM] Done");
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

- (void)createList {
  NSLog(@"[AUPM] aupm.list missing, creating a new one...");
  NSTask *cpTask = [[NSTask alloc] init];
  [cpTask setLaunchPath:@"/Applications/AUPM.app/supersling"];

  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0")) {
    int detectedJailbreak = 0;
    CFArrayRef ary = SBSCopyApplicationDisplayIdentifiers(false, false);
    for(CFIndex i = 0; i < CFArrayGetCount(ary); i++) {
        NSString *appID = (NSString *)CFArrayGetValueAtIndex(ary, i);
        if ([appID rangeOfString:@"electra"].location != NSNotFound) {
          detectedJailbreak += 1;
        }
        else if ([appID rangeOfString:@"undecimus"].location != NSNotFound) {
          detectedJailbreak += 2;
        }
    }

    switch (detectedJailbreak) {
      case 0: {
        NSLog(@"[AUPM] No jailbreak detected, perhaps it is a newer jailbreak or it is using a different app ID?");
        [self pickJailbreak:^(BOOL success, NSArray *args) {
          [cpTask setArguments:args];

          [cpTask launch];
          [cpTask waitUntilExit];
        }];
        break;
      }
      case 1: {
        NSLog(@"[AUPM] Electra detected.");
        [cpTask setArguments:[[NSArray alloc] initWithObjects: @"cp", @"-fR", @"/var/lib/aupm/default-electra.list", @"/var/lib/aupm/aupm.list", nil]];

        [cpTask launch];
        [cpTask waitUntilExit];
        break;
      }
      case 2: {
        NSLog(@"[AUPM] unc0ver detected.");
        [cpTask setArguments:[[NSArray alloc] initWithObjects: @"cp", @"-fR", @"/var/lib/aupm/default-uncover.list", @"/var/lib/aupm/aupm.list", nil]];

        [cpTask launch];
        [cpTask waitUntilExit];
        break;
      }
      default: {
        NSLog(@"[AUPM] Multiple jailbreak apps installed on device.");
        [self pickJailbreak:^(BOOL success, NSArray *args) {
          [cpTask setArguments:args];

          [cpTask launch];
          [cpTask waitUntilExit];
        }];
        break;
      }
    }
  }
  else {
  	NSLog(@"[AUPM] System version is less that 11.0, installing Cydia's repo");
    [cpTask setArguments:[[NSArray alloc] initWithObjects: @"cp", @"-fR", @"/var/lib/aupm/default.list", @"/var/lib/aupm/aupm.list", nil]];

    [cpTask launch];
    [cpTask waitUntilExit];
  }
}

- (void)pickJailbreak:(void (^)(BOOL success, NSArray *args))completion {
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Unable to detect jailbreak" message:@"AUPM could not detect which jailbreak you are using.\n\nThis is probably due to the app being installed with a different bundleID or if there are multiple jailbreak apps on the phone.\n\nPlease select your jailbreak so that default sources can be properly installed and then refresh." preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction *electraAction = [UIAlertAction actionWithTitle:@"Electra" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    [alertController dismissViewControllerAnimated:true completion:nil];
    NSArray *args = [[NSArray alloc] initWithObjects: @"cp", @"-fR", @"/var/lib/aupm/default-electra.list", @"/var/lib/aupm/aupm.list", nil];
    completion(true, args);
  }];

  UIAlertAction *uncoverAction = [UIAlertAction actionWithTitle:@"unc0ver" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    [alertController dismissViewControllerAnimated:true completion:nil];
    NSArray *args = [[NSArray alloc] initWithObjects: @"cp", @"-fR", @"/var/lib/aupm/default-uncover.list", @"/var/lib/aupm/aupm.list", nil];
    completion(true, args);
  }];

  UIAlertAction *neitherAction = [UIAlertAction actionWithTitle:@"Neither, install Telesphoreo" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
    [alertController dismissViewControllerAnimated:true completion:nil];
    NSArray *args = [[NSArray alloc] initWithObjects: @"cp", @"-fR", @"/var/lib/aupm/default.list", @"/var/lib/aupm/aupm.list", nil];
    completion(true, args);
  }];

  [alertController addAction:electraAction];
  [alertController addAction:uncoverAction];
  [alertController addAction:neitherAction];

  [self presentViewController:alertController animated:true completion:nil];
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
