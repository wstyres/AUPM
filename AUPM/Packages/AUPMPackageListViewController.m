#import "AUPMPackageListViewController.h"
#import "AUPMPackageManager.h"
#import "AUPMPackage.h"
#import "AUPMPackageViewController.h"
#import "../AUPMDatabaseManager.h"
#import "../Repos/AUPMRepo.h"
<<<<<<< HEAD
#import "../AUPMAppDelegate.h"
=======
#import "../AUPMTabBarController.h"
>>>>>>> 5f5c8c314e55e9cadb2f16539f06f39c19eed705

@implementation AUPMPackageListViewController {
	NSMutableArray *_objects;
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

	AUPMDatabaseManager *databaseManager = ((AUPMAppDelegate *)[[UIApplication sharedApplication] delegate]).databaseManager;
	if (_repo != NULL) {
<<<<<<< HEAD
=======
		AUPMDatabaseManager *databaseManager = [(AUPMTabBarController *)self.tabBarController databaseManager];
>>>>>>> 5f5c8c314e55e9cadb2f16539f06f39c19eed705
		_objects = [[databaseManager cachedPackageListForRepo:_repo] mutableCopy];

		self.title = [_repo repoName];
	}
	else {
<<<<<<< HEAD
=======
		AUPMDatabaseManager *databaseManager = [(AUPMTabBarController *)self.tabBarController databaseManager];
>>>>>>> 5f5c8c314e55e9cadb2f16539f06f39c19eed705
		_objects = [[databaseManager cachedListOfInstalledPackages] mutableCopy];

		self.title = @"Packages";
	}
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *identifier = @"PackageTableViewCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	AUPMPackage *package = _objects[indexPath.row];

	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
	}

	NSString *section = [[package section] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	NSString *iconPath = [NSString stringWithFormat:@"/Applications/Cydia.app/Sections/%@.png", section];
	UIImage *sectionImage = [UIImage imageWithContentsOfFile:iconPath];
	if (sectionImage != NULL) {
		cell.imageView.image = sectionImage;
	}
	else if (_repo != NULL) {
		cell.imageView.image = [UIImage imageWithData:[_repo icon]];
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
