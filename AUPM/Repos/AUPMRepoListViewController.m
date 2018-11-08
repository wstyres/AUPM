#import "AUPMRepoListViewController.h"

#import "Console/AUPMConsoleViewController.h"
#import "Database/AUPMRefreshViewController.h"
#import "Packages/AUPMPackageListViewController.h"
#import "Database/AUPMDatabaseManager.h"

#import "AUPMRepo.h"
#import "AUPMRepoManager.h"
#import "AUPMAppDelegate.h"
#import "AUPMTabBarController.h"

@interface AUPMRepoListViewController ()
@property (nonatomic, strong) RLMResults *objects;
@property (nonatomic, strong) RLMNotificationToken *notification;
@end

@implementation AUPMRepoListViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.objects = [[AUPMRepo allObjects] sortedResultsUsingKeyPath:@"repoName" ascending:YES];
	[self setupUI];

	__weak AUPMRepoListViewController *weakSelf = self;
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
	self.title = @"Sources";
	UIBarButtonItem *refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshPackages)];
	self.navigationItem.rightBarButtonItem = refreshItem;

	UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addRepo)];
	self.navigationItem.leftBarButtonItem = addItem;
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
	AUPMRepo *repo = _objects[indexPath.row];
	if ([[repo repoName] isEqual:@"xTM3x Repo"]) {
		return NO;
	}

	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];
		[repoManager deleteSource:[_objects objectAtIndex:indexPath.row]];
	}
}

#pragma mark - Adding Repos

- (void)addRepo {
	[self showAddRepoAlert:NULL];
}

- (void)showAddRepoAlert:(NSURL *)url {
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Enter URL" message:nil preferredStyle:UIAlertControllerStyleAlert];

	[alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
	[alertController addAction:[UIAlertAction actionWithTitle:@"Add"
		style:UIAlertActionStyleDefault
		handler:^(UIAlertAction * _Nonnull action) {
			[self dismissViewControllerAnimated:true completion:nil];

			AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];
			NSString *sourceURL = alertController.textFields[0].text;

			UIAlertController *wait = [UIAlertController alertControllerWithTitle:@"Please Wait..." message:@"Verifying Source" preferredStyle:UIAlertControllerStyleAlert];
			[self presentViewController:wait animated:true completion:nil];

			[repoManager addSourceWithURL:sourceURL response:^(BOOL success, NSString *error, NSURL *url) {
				if (!success) {
					NSLog(@"[AUPM] Could not add source %@ due to error %@", url.absoluteString, error);

	  			[wait dismissViewControllerAnimated:true completion:^{
						[self presentVerificationFailedAlert:error url:url];
					}];
				}
				else {
					[wait dismissViewControllerAnimated:true completion:^{
						NSLog(@"[AUPM] Added source.");
						AUPMRefreshViewController *refreshViewController = [[AUPMRefreshViewController alloc] initWithAction:1];
						[self presentViewController:refreshViewController animated:true completion:nil];
					}];
				}
			}];
		}
	]];

	[alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
		if (url != NULL) {
			textField.text = [url absoluteString];
		}
		else {
			textField.text = @"http://";
		}
		textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		textField.autocorrectionType = UITextAutocorrectionTypeNo;
		textField.keyboardType = UIKeyboardTypeURL;
		textField.returnKeyType = UIReturnKeyNext;
	}];

	[self presentViewController:alertController animated:true completion:nil];
}

- (void)presentVerificationFailedAlert:(NSString *)message url:(NSURL *)url {
	dispatch_async(dispatch_get_main_queue(), ^{
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Unable to verify Repo" message:message preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
			[alertController dismissViewControllerAnimated:true completion:nil];
			[self showAddRepoAlert:url];
		}];
		[alertController addAction:okAction];

		[self presentViewController:alertController animated:true completion:nil];
	});
}

@end
