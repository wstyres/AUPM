#import "AUPMRepoListViewController.h"
#import "../AUPMConsoleViewController.h"
#import "AUPMRepo.h"
#import "AUPMRepoManager.h"
#import "../AUPMRefreshViewController.h"
#import "../Packages/AUPMPackageListViewController.h"
#import "../AUPMDatabaseManager.h"
#import "../AUPMAppDelegate.h"

@implementation AUPMRepoListViewController {
	NSMutableArray *_objects;
}

- (void)loadView {
	[super loadView];

	AUPMDatabaseManager *databaseManager = ((AUPMAppDelegate *)[[UIApplication sharedApplication] delegate]).databaseManager;
	_objects = [[databaseManager cachedListOfRepositories] mutableCopy];

	UIBarButtonItem *refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshPackages)];
	self.navigationItem.rightBarButtonItem = refreshItem;

	UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showAddRepoAlert)];
	self.navigationItem.leftBarButtonItem = addItem;

	self.title = @"Sources";
}

- (void)refreshPackages {
	AUPMRefreshViewController *dataLoadViewController = [[AUPMRefreshViewController alloc] initWithAction:1];

	[self presentViewController:dataLoadViewController animated:true completion:nil];
}

- (void)fullRefresh {
	AUPMRefreshViewController *dataLoadViewController = [[AUPMRefreshViewController alloc] initWithAction:0];

	[self presentViewController:dataLoadViewController animated:true completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	AUPMDatabaseManager *databaseManager = ((AUPMAppDelegate *)[[UIApplication sharedApplication] delegate]).databaseManager;
	_objects = [[databaseManager cachedListOfRepositories] mutableCopy];

	[[self tableView] reloadData];
}

- (void)showAddRepoAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Enter URL"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Add"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
                                                          UITextField *textField = alertController.textFields[0];
                                                          [self addSourceWithURL:textField.text];
                                                      }]];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = @"http://";
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.keyboardType = UIKeyboardTypeURL;
        textField.returnKeyType = UIReturnKeyNext;
    }];
    [self presentViewController:alertController animated:true completion:nil];
}

- (void)addSourceWithURL:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        HBLogError(@"invalid URL: %@", urlString);
		return;
    }
	HBLogInfo(@"Adding repo: %@", urlString);

	// AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];
	// [repoManager addSource:url];
	// [self fullRefresh];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *identifier = @"RepoTableViewCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	AUPMRepo *repo = _objects[indexPath.row];

	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
	}

    cell.textLabel.text = [repo repoName];
    cell.detailTextLabel.text = [repo repoURL];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = [UIImage imageWithData:[repo icon]];

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
	AUPMRepo *repo = _objects[indexPath.row];
	AUPMPackageListViewController *packageListVC = [[AUPMPackageListViewController alloc] initWithRepo:repo];
    [self.navigationController pushViewController:packageListVC animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		//AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];
		//[repoManager deleteSource:[_objects objectAtIndex:indexPath.row]];
		[_objects removeObjectAtIndex:indexPath.row];
		[tableView reloadData];
    }
}

@end
