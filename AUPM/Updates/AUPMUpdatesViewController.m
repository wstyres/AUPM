#import "AUPMUpdatesViewController.h"
#import "../Packages/AUPMPackage.h"
#import "../Packages/AUPMPackageViewController.h"
#import "../AUPMTabBarController.h"

@interface AUPMUpdatesViewController ()
@property (nonatomic, strong) RLMResults<AUPMPackage *> *objects;
@property (nonatomic, strong) RLMNotificationToken *notification;
@property (nonatomic, strong) NSArray<NSArray <AUPMPackage *> *> *packages;
@end

@implementation AUPMUpdatesViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.objects = [[AUPMPackage allObjects] sortedResultsUsingKeyPath:@"updated" ascending:false];
	[self setupUI];
	self.packages = [self sortPackages];

	// __weak AUPMUpdatesViewController *weakSelf = self;
	// self.notification = [self.objects addNotificationBlock:^(RLMResults *data, RLMCollectionChange *changes, NSError *error) {
	// 	if (error) {
	// 		NSLog(@"[AUPM] Failed to open Realm on background worker: %@", error);
	// 		return;
	// 	}
	//
	// 	UITableView *tv = weakSelf.tableView;
	// 	if (!changes) {
	// 		[tv reloadData];
	// 		return;
	// 	}
	//
	// 	[tv beginUpdates];
	// 	[tv deleteRowsAtIndexPaths:[changes deletionsInSection:0] withRowAnimation:UITableViewRowAnimationAutomatic];
	// 	[tv insertRowsAtIndexPaths:[changes insertionsInSection:0] withRowAnimation:UITableViewRowAnimationAutomatic];
	// 	[tv reloadRowsAtIndexPaths:[changes modificationsInSection:0] withRowAnimation:UITableViewRowAnimationAutomatic];
	// 	[tv endUpdates];
	// }];
}

- (NSArray *)sortPackages { //This is super slow, probably going to do something with realm along the lines of AUPMDateKeeper in the future
	NSLog(@"[AUPM] Trying to sort...");
	NSDate *lastDate = self.objects.firstObject.updated;
	NSMutableArray *lastGroup = [NSMutableArray<AUPMPackage *> new];
	NSMutableArray *groups = [NSMutableArray<NSMutableArray<AUPMPackage *> *> new];

	for (AUPMPackage *package in self.objects) {
		NSDate *packageDate = package.updated;

    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSUInteger unitFlags = NSCalendarUnitMinute;
    NSDateComponents *components = [gregorian components:unitFlags fromDate:packageDate toDate:lastDate options:0];

		if ([components minute] > 5) {
			lastDate = packageDate;
			[groups addObject:lastGroup];
			NSMutableArray *newGroup = [NSMutableArray new];
			[newGroup addObject:package];
			lastGroup = newGroup;
		}
		else {
			[lastGroup addObject:package];
		}
	}
	[groups addObject:lastGroup];

	return (NSArray *)groups;
}

- (void)setupUI {
	self.title = @"Updates";

	UIBarButtonItem *refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshPackages)];
	self.navigationItem.rightBarButtonItem = refreshItem;
}

- (void)refreshPackages {
	// AUPMTabBarController *tabController = (AUPMTabBarController *)self.tabBarController;
	// [tabController performBackgroundRefresh:true];
	[self.tableView reloadData];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.packages.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.packages[section].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSDate *date = self.packages[section].firstObject.updated;
	NSString *dateString = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
	return dateString;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *identifier = @"UpdatesTableViewCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	AUPMPackage *package = self.packages[indexPath.section][indexPath.row];

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
