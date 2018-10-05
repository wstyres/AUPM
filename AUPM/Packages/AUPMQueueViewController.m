#import "AUPMQueueViewController.h"
#import "../AUPMQueue.h"
#import "../AUPMConsoleViewController.h"

@implementation AUPMQueueViewController {
  AUPMQueue *_queue;
}

- (void)loadView {
  [super loadView];

  _queue = [AUPMQueue sharedInstance];

  UIBarButtonItem *confirmButton = [[UIBarButtonItem alloc] initWithTitle:@"Confirm" style:UIBarButtonItemStyleDone target:self action:@selector(confirm)];
  self.navigationItem.rightBarButtonItem = confirmButton;

  UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Confirm" style:UIBarButtonItemStyleDone target:self action:@selector(cancel)];
  self.navigationItem.leftBarButtonItem = cancelButton;

  self.title = @"Queue";
}

- (void)confirm {
  AUPMConsoleViewController *console = [[AUPMConsoleViewController alloc] init];
  [[self navigationController] pushViewController:console animated:true];
}

- (void)cancel {
  [self dismissViewControllerAnimated:true completion:nil];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case 0: {
      return [_queue numberOfPackagesForQueue:@"install"];
      break;
    }
    case 1: {
      return [_queue numberOfPackagesForQueue:@"remove"];
      break;
    }
    case 2: {
      return [_queue numberOfPackagesForQueue:@"reinstall"];
      break;
    }
    case 3: {
      return [_queue numberOfPackagesForQueue:@"upgrade"];
      break;
    }
    default: {
      return 0;
      break;
    }
  }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
    case 0: {
      return @"Install";
      break;
    }
    case 1: {
      return @"Remove";
      break;
    }
    case 2: {
      return @"Reinstall";
      break;
    }
    case 3: {
      return @"Upgrade";
      break;
    }
    default: {
      return @"AXOLOTL";
      break;
    }
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *identifier = @"QueuePackageTableViewCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
  NSString *package;
  switch (indexPath.section) {
    case 0: {
      package = [_queue packageInQueueForAction:AUPMQueueActionInstall atIndex:indexPath.row];
      break;
    }
    case 1: {
      package = [_queue packageInQueueForAction:AUPMQueueActionRemove atIndex:indexPath.row];
      break;
    }
    case 2: {
      package = [_queue packageInQueueForAction:AUPMQueueActionReinstall atIndex:indexPath.row];
      break;
    }
    case 3: {
      package = [_queue packageInQueueForAction:AUPMQueueActionUpgrade atIndex:indexPath.row];
      break;
    }
    default: {
      package = @"MY TIME HAS COME TO BURN";
      break;
    }
  }

	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
	}

	cell.textLabel.text = package;

	return cell;
}
@end
