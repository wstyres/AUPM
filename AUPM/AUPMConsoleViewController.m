#import "AUPMConsoleViewController.h"
#import "NSTask.h"
#import "AUPMAppDelegate.h"
#import "AUPMDatabaseManager.h"
#import "AUPMTabBarController.h"
#import "Packages/AUPMPackage.h"

@implementation AUPMConsoleViewController {
    NSArray *_packages;
    int _action;
    UITextView *_consoleOutputView;
}

- (id)initAndInstall:(NSArray *)packages {
  self = [super init];

  if (self) {
      _packages = packages;
      _action = 0;
  }

  return self;
}

- (id)initAndRemove:(NSArray *)packages {
  self = [super init];

  if (self) {
      _packages = packages;
      _action = 1;
  }

  return self;
}

- (id)initAndUpgrade {
  self = [super init];

  if (self) {
      _action = 2;
  }

  return self;
}

- (void)loadView {
    [super loadView];
    CGFloat height = [[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height;
	  _consoleOutputView = [[UITextView alloc] initWithFrame:CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height - height)];
    _consoleOutputView.editable = false;
    [self.view addSubview:_consoleOutputView];

    NSMutableArray *command = [[NSMutableArray alloc] initWithObjects:@"apt-get", @"-o", @"Dir::Etc::SourceList=/var/lib/aupm/aupm.list", @"-o", @"Dir::State::Lists=/var/lib/aupm/lists", @"-o", @"Dir::Etc::SourceParts=/var/lib/aupm/lists/partial/false", @"-y", @"--force-yes", nil];
    NSTask *task = [[NSTask alloc] init];
    switch (_action) {
      case 0: {
        [command insertObject:@"install" atIndex:1];
        for (AUPMPackage *package in _packages) {
          [command insertObject:[NSString stringWithFormat:@"%@=%@", [package packageIdentifier], [package version]] atIndex:2];
        }

      	[task setLaunchPath:@"/Applications/AUPM.app/supersling"];
      	[task setArguments:command];
        break;
      }
      case 1: {
        [command insertObject:@"remove" atIndex:1];
        for (AUPMPackage *package in _packages) {
          [command insertObject:[package packageIdentifier] atIndex:2];
        }

        [task setLaunchPath:@"/Applications/AUPM.app/supersling"];
        [task setArguments:command];
        break;
      }
      case 2: {
        [command insertObject:@"upgrade" atIndex:1];

        [task setLaunchPath:@"/Applications/AUPM.app/supersling"];
        [task setArguments:command];
        break;
      }
      default: {
        [self dismissConsole];
        break;
      }
    }

    NSLog(@"[AUPM] Command: %@", command);

    NSPipe *pipe = [[NSPipe alloc] init];
    [task setStandardOutput:pipe];
    [task setStandardError:pipe];

    NSFileHandle *output = [pipe fileHandleForReading];
    [output waitForDataInBackgroundAndNotify];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedData:) name:NSFileHandleDataAvailableNotification object:output];

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissConsole)];
    UINavigationItem *navItem = self.navigationItem;
    task.terminationHandler = ^(NSTask *task){
        dispatch_async(dispatch_get_main_queue(), ^{
            navItem.rightBarButtonItem = doneButton;
        });
    };

    [task launch];
}

// - (void)postInstallActions {
//   AUPMPackageManager *packageManager = [[AUPMPackageManager alloc] init];
//
//   UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"My Alert" message:@"This is an alert." preferredStyle:UIAlertControllerStyleAlert];
//
//   UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
//
//   [alert addAction:defaultAction];
//   [self presentViewController:alert animated:YES completion:nil];
// }

- (void)dismissConsole {
  AUPMDatabaseManager *databaseManager = ((AUPMAppDelegate *)[[UIApplication sharedApplication] delegate]).databaseManager;
  [databaseManager updateEssentials:^(BOOL success) {
    AUPMTabBarController *tabController = (AUPMTabBarController *)((AUPMAppDelegate *)[[UIApplication sharedApplication] delegate]).window.rootViewController;
    [tabController updatePackageTableView];

    [self dismissViewControllerAnimated:true completion:nil];
  }];
}

- (void)receivedData:(NSNotification *)notif {
    NSFileHandle *fh = [notif object];
    NSData *data = [fh availableData];

    if (data.length > 0) {
        [fh waitForDataInBackgroundAndNotify];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [_consoleOutputView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:str]];

        if (_consoleOutputView.text.length > 0 ) {
            NSRange bottom = NSMakeRange(_consoleOutputView.text.length -1, 1);
            [_consoleOutputView scrollRangeToVisible:bottom];
        }
    }
}

@end
