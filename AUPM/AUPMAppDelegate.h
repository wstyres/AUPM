@class AUPMDatabaseManager;
@class AUPMQueue;

@interface AUPMAppDelegate : UIResponder <UITabBarControllerDelegate>

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UITabBarController *tabBarController;
@property (nonatomic, retain) AUPMDatabaseManager *databaseManager;

@end
