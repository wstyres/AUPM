@class NSTask;

@interface AUPMConsoleViewController : UIViewController
- (id)initAndInstall:(NSArray *)packages;
- (id)initAndRemove:(NSArray *)packages;
- (id)initAndUpgrade;
@end
