#import "AUPMPackageListViewController.h"
#import "AUPMPackageManager.h"
#import "AUPMPackage.h"
#import "AUPMPackageViewController.h"
#import "../AUPMDatabaseManager.h"
#import "../Repos/AUPMRepo.h"
#import "../AUPMAppDelegate.h"

@implementation AUPMPackageListViewController {
	RLMArray<AUPMPackage *> *_objects;
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
		_objects = _repo.packages;

		self.title = [_repo repoName];
	}
	else {
		_objects = (RLMArray *)[[AUPMPackage objectsWhere:@"installed = true"] sortedResultsUsingDescriptors:@[
	    [RLMSortDescriptor sortDescriptorWithKeyPath:@"packageName" ascending:YES]
	  ]];

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

	NSString *dateString = [NSDateFormatter localizedStringFromDate:[package updated] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterFullStyle];

	cell.detailTextLabel.text = dateString;//[NSString stringWithFormat:@"%@ (%@)", [package packageIdentifier], [package version]];

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
