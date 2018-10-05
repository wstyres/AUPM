@class AUPMPackage;

#import "AUPMQueueAction.h"

@interface AUPMQueue : NSObject
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray *> *managedQueue;
+ (id)sharedInstance;
- (void)addPackage:(AUPMPackage *)package toQueueWithAction:(AUPMQueueAction)action;
- (void)addPackages:(NSArray<AUPMPackage *> *)packages toQueueWithAction:(AUPMQueueAction)action;
- (void)removePackage:(NSString *)packageIdentifier fromQueueWithAction:(AUPMQueueAction)action;
- (NSArray *)tasksForQueue;
- (int)numberOfPackagesForQueue:(NSString *)queue;
- (NSString *)packageInQueueForAction:(AUPMQueueAction)action atIndex:(int)index;
- (void)clearQueue;
- (NSArray *)actionsToPerform;
@end
