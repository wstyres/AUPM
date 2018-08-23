#import "AUPMDebugViewController.h"
#import "AUPMRefreshViewController.h"

@implementation AUPMDebugViewController

- (void)loadView {
    [super loadView];

    [self nukeDatabase];
}

- (void)nukeDatabase {
    AUPMRefreshViewController *refreshViewController = [[AUPMRefreshViewController alloc] init];

    [[UIApplication sharedApplication] keyWindow].rootViewController = refreshViewController;
}

@end
