#import "AUPMPackageListViewController.h"
#import "AUPMPackageManager.h"
#import "AUPMPackage.h"
#import "AUPMPackageViewController.h"
#import "../AUPMDatabaseManager.h"
#import "../Repos/AUPMRepo.h"
#import "../AUPMAppDelegate.h"
#import "../AUPMTabBarController.h"
#import "../NSTask.h"
#import "../AUPMConsoleViewController.h"

@implementation AUPMPackageListViewController {
	NSArray *_updateObjects;
	BOOL _hasUpdates;
	RLMResults<AUPMPackage *> *_objects;
	AUPMRepo *_repo;
}

- (id)initWithRepo:(AUPMRepo *)repo {
	self = [super init];
    if (self) {
        _repo = repo;
    }
    return self;
}

- (void)loadView {
	[super loadView];

	if (_repo != NULL) {
		_objects = [[_repo packages] sortedResultsUsingDescriptors:@[
	    [RLMSortDescriptor sortDescriptorWithKeyPath:@"packageName" ascending:YES]
	  ]];

		self.title = [_repo repoName];
	}
	else {
		[self refreshTable];

		self.title = @"Packages";
	}
}

- (void)refreshTable {
	_updateObjects = [((AUPMTabBarController *)self.tabBarController) updateObjects];

	if (_updateObjects.count > 0) {
		_hasUpdates = true;

		UIBarButtonItem *upgradeItem = [[UIBarButtonItem alloc] initWithTitle:@"Upgrade All" style:UIBarButtonItemStyleDone target:self action:@selector(upgradePackages)];
		self.navigationItem.rightBarButtonItem = upgradeItem;
	}

	_objects = [[AUPMPackage objectsWhere:@"installed = true"] sortedResultsUsingDescriptors:@[
		[RLMSortDescriptor sortDescriptorWithKeyPath:@"packageName" ascending:YES]
	]];

	[self.tableView reloadData];
}

- (void)upgradePackages {
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:@"/Applications/AUPM.app/supersling"];
	NSArray *arguments = [[NSArray alloc] initWithObjects: @"apt-get", @"upgrade", @"-o", @"Dir::Etc::SourceList=/var/lib/aupm/aupm.list", @"-o", @"Dir::State::Lists=/var/lib/aupm/lists", @"-o", @"Dir::Etc::SourceParts=/var/lib/aupm/lists/partial/false", @"-y", @"--force-yes", nil];
	[task setArguments:arguments];

	AUPMConsoleViewController *console = [[AUPMConsoleViewController alloc] initWithTask:task];
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:console];
	[self presentViewController:navController animated:true completion:nil];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (_hasUpdates) {
		return 2;
	}
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (_hasUpdates && section == 0) {
		return [_updateObjects count];
	}
	else {
		return [_objects count];
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (_hasUpdates && section == 0) {
		return @"Updates";
	}
	return @"Installed Packages";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *identifier = @"PackageTableViewCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	AUPMPackage *package;

	if (_hasUpdates && indexPath.section == 0) {
		package = _updateObjects[indexPath.row];
	}
	else {
		package = _objects[indexPath.row];
	}

	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
	}

	NSString *section = [[package section] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	if ([section characterAtIndex:[section length] - 1] == ')') {
		NSArray *items = [section componentsSeparatedByString:@"("]; //Remove () from section
		section = [items[0] substringToIndex:[items[0] length] - 1];
	}
	NSString *iconPath = [NSString stringWithFormat:@"/Applications/Cydia.app/Sections/%@.png", section];
	NSError *error;
	NSData *data = [NSData dataWithContentsOfFile:iconPath options:0 error:&error];
	UIImage *sectionImage = [UIImage imageWithData:data];
	if (sectionImage != NULL) {
		cell.imageView.image = sectionImage;
	}
	else if (_repo != NULL) {
		cell.imageView.image = [UIImage imageWithData:[_repo icon]];
	}

	if (error != nil) {
		NSLog(@"[AUPM] %@", error);
	}

	cell.textLabel.text = [package packageName];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", [package packageIdentifier], [package version]];

	CGSize itemSize = CGSizeMake(35, 35);
  UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
  CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
  [cell.imageView.image drawInRect:imageRect];
  cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

	return cell;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	AUPMPackage *package = _objects[indexPath.row];
	AUPMPackageViewController *packageVC = [[AUPMPackageViewController alloc] initWithPackage:package];
    [self.navigationController pushViewController:packageVC animated:YES];
}

@end
