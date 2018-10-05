#import "AUPMQueue.h"
#import "Packages/AUPMPackage.h"

@implementation AUPMQueue
+ (id)sharedInstance {
    static AUPMQueue *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [AUPMQueue new];
    });
    return instance;
}

- (id)init {
    self = [super init];

    if (self) {
        _managedQueue = [NSMutableDictionary new];
        [_managedQueue setObject:@[] forKey:@"install"];
        [_managedQueue setObject:@[] forKey:@"remove"];
        [_managedQueue setObject:@[] forKey:@"reinstall"];
        [_managedQueue setObject:@[] forKey:@"upgrade"];
    }

    return self;
}

- (void)addPackage:(AUPMPackage *)package toQueueWithAction:(AUPMQueueAction)action {
  switch (action) {
    case AUPMQueueActionInstall: {
      NSMutableArray *installArray = [_managedQueue[@"install"] mutableCopy];
      [installArray addObject:[package packageIdentifier]];
      [_managedQueue setObject:installArray forKey:@"install"];
    }
    case AUPMQueueActionRemove: {
      NSMutableArray *removeArray = [_managedQueue[@"remove"] mutableCopy];
      [removeArray addObject:[package packageIdentifier]];
      [_managedQueue setObject:removeArray forKey:@"remove"];
    }
    case AUPMQueueActionReinstall: {
      NSMutableArray *reinstallArray = [_managedQueue[@"reinstall"] mutableCopy];
      [reinstallArray addObject:[package packageIdentifier]];
      [_managedQueue setObject:reinstallArray forKey:@"reinstall"];
    }
    case AUPMQueueActionUpgrade: {
      NSMutableArray *upgradeArray = [_managedQueue[@"upgrade"] mutableCopy];
      [upgradeArray addObject:[package packageIdentifier]];
      [_managedQueue setObject:upgradeArray forKey:@"upgrade"];
    }
  }
}

- (void)addPackages:(NSArray<AUPMPackage *> *)packages toQueueWithAction:(AUPMQueueAction)action {
  for (AUPMPackage *package in packages) {
    switch (action) {
      case AUPMQueueActionInstall: {
        NSMutableArray *installArray = [_managedQueue[@"install"] mutableCopy];
        [installArray addObject:[package packageIdentifier]];
        [_managedQueue setObject:installArray forKey:@"install"];
      }
      case AUPMQueueActionRemove: {
        NSMutableArray *removeArray = [_managedQueue[@"remove"] mutableCopy];
        [removeArray addObject:[package packageIdentifier]];
        [_managedQueue setObject:removeArray forKey:@"remove"];
      }
      case AUPMQueueActionReinstall: {
        NSMutableArray *reinstallArray = [_managedQueue[@"reinstall"] mutableCopy];
        [reinstallArray addObject:[package packageIdentifier]];
        [_managedQueue setObject:reinstallArray forKey:@"reinstall"];
      }
      case AUPMQueueActionUpgrade: {
        NSMutableArray *upgradeArray = [_managedQueue[@"upgrade"] mutableCopy];
        [upgradeArray addObject:[package packageIdentifier]];
        [_managedQueue setObject:upgradeArray forKey:@"upgrade"];
      }
    }
  }
}

- (void)removePackage:(NSString *)packageIdentifier fromQueueWithAction:(AUPMQueueAction)action {
  switch (action) {
    case AUPMQueueActionInstall: {
      NSMutableArray *installArray = [_managedQueue[@"install"] mutableCopy];
      [installArray removeObject:packageIdentifier];
      [_managedQueue setObject:installArray forKey:@"install"];
    }
    case AUPMQueueActionRemove: {
      NSMutableArray *removeArray = [_managedQueue[@"remove"] mutableCopy];
      [removeArray removeObject:packageIdentifier];
      [_managedQueue setObject:removeArray forKey:@"remove"];
    }
    case AUPMQueueActionReinstall: {
      NSMutableArray *reinstallArray = [_managedQueue[@"reinstall"] mutableCopy];
      [reinstallArray removeObject:packageIdentifier];
      [_managedQueue setObject:reinstallArray forKey:@"reinstall"];
    }
    case AUPMQueueActionUpgrade: {
      NSMutableArray *upgradeArray = [_managedQueue[@"upgrade"] mutableCopy];
      [upgradeArray removeObject:packageIdentifier];
      [_managedQueue setObject:upgradeArray forKey:@"upgrade"];
    }
  }
}
@end
