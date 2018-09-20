#import "AUPMRepoListViewController.h"
#import "../AUPMConsoleViewController.h"
#import "AUPMRepo.h"
#import "AUPMRepoManager.h"
#import "../AUPMRefreshViewController.h"
#import "../Packages/AUPMPackageListViewController.h"
#import "../AUPMDatabaseManager.h"
#import "../AUPMAppDelegate.h"
#import "../AUPMTabBarController.h"
#import <Realm/Realm.h>

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

	UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showAddRepoAlert)];
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

- (void)showAddRepoAlert {
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Enter URL" message:nil preferredStyle:UIAlertControllerStyleAlert];

	[alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
	[alertController addAction:[UIAlertAction actionWithTitle:@"Add"
	style:UIAlertActionStyleDefault
	handler:^(UIAlertAction * _Nonnull action) {
		UITextField *textField = alertController.textFields[0];
		[self addSourceWithURL:textField.text];
	}
	]];
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
		NSLog(@"invalid URL: %@", urlString);
		return;
	}

	[self verifySourceExists:[url URLByAppendingPathComponent:@"Packages.bz2"]];
}

- (void)verifySourceExists:(NSURL *)url {
	NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
	NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
	request.HTTPMethod = @"HEAD";

	NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self receivedPackageVerification:response error:error];
		});
	}];
	[task resume];
}

- (void)receivedPackageVerification:(NSURLResponse *)response error:(NSError *)error {
	if (error) {
		NSLog(@"[AUPM] Error verifying repository: %@", error);
		[self presentVerificationFailedAlert:error.localizedDescription];
		return;
	}

	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

	NSURL *url = [httpResponse.URL URLByDeletingLastPathComponent];
	if (httpResponse.statusCode != 200) {
		NSString *errorMessage = [NSString stringWithFormat:@"Expected status from url %@, received: %d", url, (int)httpResponse.statusCode];
		NSLog(@"[AUPM] %@", errorMessage);
		[self presentVerificationFailedAlert:errorMessage];
		return;
	}

	NSLog(@"[AUPM] Verified source %@", url);
	[self addRepository:url];
}

- (void)presentVerificationFailedAlert:(NSString *)message {
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Unable to verify Repo" message:message preferredStyle:UIAlertControllerStyleAlert];

	[alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];

	[self presentViewController:alertController animated:true completion:nil];
}

- (void)addRepository:(NSURL *)sourceURL {
	NSLog(@"[AUPM] Adding %@ to database", sourceURL);
	AUPMRepoManager *repoManager = [[AUPMRepoManager alloc] init];
	[repoManager addSource:sourceURL completion:^(BOOL success) {
		if (success) {
			AUPMRefreshViewController *refreshViewController = [[AUPMRefreshViewController alloc] initWithAction:1];
			[self presentViewController:refreshViewController animated:true completion:nil];
		}
		else {
			NSLog(@"[AUPM] Failed to add repo");
		}
	}];
}

@end
