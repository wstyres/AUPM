#import "AUPMUpdatesViewController.h"
#import "../Packages/AUPMPackage.h"
#import "../Packages/AUPMPackageViewController.h"
#import "../AUPMTabBarController.h"

@interface AUPMUpdatesViewController ()
@property (nonatomic, strong) RLMResults *objects;
@property (nonatomic, strong) RLMNotificationToken *notification;
@end

@implementation AUPMUpdatesViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.objects = [[AUPMPackage allObjects] sortedResultsUsingKeyPath:@"updated" ascending:YES];
	[self setupUI];

	__weak AUPMUpdatesViewController *weakSelf = self;
	self.notification = [self.objects addNotificationBlock:^(RLMResults *data, RLMCollectionChange *changes, NSError *error) {
		if (error) {
			NSLog(@"[AUPM] Failed to open Realm on background worker: %@", error);
			return;
		}

		UITableView *tv = weakSelf.tableView;
		if (!changes) {
			[tv reloadData];
			return;
		}

		[tv beginUpdates];
		[tv deleteRowsAtIndexPaths:[changes deletionsInSection:0] withRowAnimation:UITableViewRowAnimationAutomatic];
		[tv insertRowsAtIndexPaths:[changes insertionsInSection:0] withRowAnimation:UITableViewRowAnimationAutomatic];
		[tv reloadRowsAtIndexPaths:[changes modificationsInSection:0] withRowAnimation:UITableViewRowAnimationAutomatic];
		[tv endUpdates];
	}];
}

- (void)setupUI {
	self.title = @"Updates";
	UIBarButtonItem *refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshPackages)];
	self.navigationItem.rightBarButtonItem = refreshItem;
}

- (void)refreshPackages {
	AUPMTabBarController *tabController = (AUPMTabBarController *)self.tabBarController;
	[tabController performBackgroundRefresh:true];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *identifier = @"UpdatesTableViewCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	AUPMPackage *package = _objects[indexPath.row];

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
	// else if ([package repo] != NULL) {
	// 	cell.imageView.image = [UIImage imageWithData:[[package repo] icon]];
	// }

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
