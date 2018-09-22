#import "AUPMSearchViewController.h"
#import "../Packages/AUPMPackage.h"
#import "../Repos/AUPMRepo.h"
#import "../Packages/AUPMPackageViewController.h"

@interface AUPMSearchViewController ()
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) RLMResults<AUPMPackage *> *results;
@end

@implementation AUPMSearchViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 64, 320, 40)];
  self.searchBar.placeholder = @"Search Packages";
  self.searchBar.delegate = self;
  [self.view addSubview:self.searchBar];

  self.tableView.contentInset = UIEdgeInsetsMake(self.searchBar.frame.size.height, 0, 0, 0);
  self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(self.searchBar.frame.size.height, 0, 0, 0);

  self.title = @"Search";
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  CGRect frame = self.searchBar.frame;
  frame.origin.y = scrollView.contentOffset.y + 64;
  self.searchBar.frame = frame;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
  self.results = [[AUPMPackage allObjects] objectsWhere:@"packageName CONTAINS[cd] %@", searchText];
  [self.tableView reloadData];
}

- (void) searchBarSearchButtonClicked:(UISearchBar*) theSearchBar {
  [theSearchBar resignFirstResponder];
  [theSearchBar setShowsCancelButton:NO animated:YES];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
  [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
  [searchBar resignFirstResponder];
  [searchBar setShowsCancelButton:NO animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *identifier = @"SearchPackageTableViewCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	AUPMPackage *package = self.results[indexPath.row];

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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	AUPMPackage *package = self.results[indexPath.row];
	AUPMPackageViewController *packageVC = [[AUPMPackageViewController alloc] initWithPackage:package];
  [self.navigationController pushViewController:packageVC animated:YES];
}

@end
