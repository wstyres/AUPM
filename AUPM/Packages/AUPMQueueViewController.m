#import "AUPMQueueViewController.h"
#import "../AUPMQueue.h"
#import "../AUPMConsoleViewController.h"
#import "../AUPMAppDelegate.h"
#import "../AUPMTabBarController.h"

@implementation AUPMQueueViewController {
  AUPMQueue *_queue;
}

- (void)loadView {
  [super loadView];

  _queue = [AUPMQueue sharedInstance];

  UIBarButtonItem *confirmButton = [[UIBarButtonItem alloc] initWithTitle:@"Confirm" style:UIBarButtonItemStyleDone target:self action:@selector(confirm)];
  self.navigationItem.rightBarButtonItem = confirmButton;

  UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
  self.navigationItem.leftBarButtonItem = cancelButton;

  self.title = @"Queue";
}

- (void)confirm {
  AUPMConsoleViewController *console = [[AUPMConsoleViewController alloc] init];
  [[self navigationController] pushViewController:console animated:true];
}

- (void)cancel {
  AUPMTabBarController *tabController = (AUPMTabBarController *)((AUPMAppDelegate *)[[UIApplication sharedApplication] delegate]).window.rootViewController;
  [tabController updatePackageTableView];

  [self dismissViewControllerAnimated:true completion:nil];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [[_queue actionsToPerform] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSString *action = [[_queue actionsToPerform] objectAtIndex:section];
  return [_queue numberOfPackagesForQueue:action];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [[_queue actionsToPerform] objectAtIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *identifier = @"QueuePackageTableViewCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
  NSString *action = [[_queue actionsToPerform] objectAtIndex:indexPath.section];
  NSString *package;

  if ([action isEqual:@"Install"]) {
    package = [_queue packageInQueueForAction:AUPMQueueActionInstall atIndex:indexPath.row];
  }
  else if ([action isEqual:@"Remove"]) {
    package = [_queue packageInQueueForAction:AUPMQueueActionRemove atIndex:indexPath.row];
  }
  else if ([action isEqual:@"Reinstall"]) {
    package = [_queue packageInQueueForAction:AUPMQueueActionReinstall atIndex:indexPath.row];
  }
  else if ([action isEqual:@"Upgrade"]) {
    package = [_queue packageInQueueForAction:AUPMQueueActionUpgrade atIndex:indexPath.row];
  }
  else {
    package = @"MY TIME HAS COME TO BURN";
  }

	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
	}

	cell.textLabel.text = package;

	return cell;
}
@end
