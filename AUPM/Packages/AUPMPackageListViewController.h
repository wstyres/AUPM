@class AUPMRepo;

@interface AUPMPackageListViewController : UITableViewController
- (id)initWithRepo:(AUPMRepo *)repo;
- (void)refreshTable;
@end
