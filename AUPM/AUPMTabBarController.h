@class AUPMDatabaseManager;

@interface AUPMTabBarController : UITabBarController {
  AUPMDatabaseManager *_databaseManager;
}
-(AUPMDatabaseManager *)databaseManager;
@end
