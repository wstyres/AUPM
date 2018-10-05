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
        [_managedQueue setObject:@[] forKey:@"Install"];
        [_managedQueue setObject:@[] forKey:@"Remove"];
        [_managedQueue setObject:@[] forKey:@"Reinstall"];
        [_managedQueue setObject:@[] forKey:@"Upgrade"];
    }

    return self;
}

- (void)addPackage:(AUPMPackage *)package toQueueWithAction:(AUPMQueueAction)action {
  switch (action) {
    case AUPMQueueActionInstall: {
      NSMutableArray *installArray = [_managedQueue[@"Install"] mutableCopy];
      if (![installArray containsObject:[NSString stringWithFormat:@"%@=%@", [package packageIdentifier], [package version]]]) {
        [installArray addObject:[NSString stringWithFormat:@"%@=%@", [package packageIdentifier], [package version]]];
        [_managedQueue setObject:installArray forKey:@"Install"];
      }
      break;
    }
    case AUPMQueueActionRemove: {
      NSMutableArray *removeArray = [_managedQueue[@"Remove"] mutableCopy];
      if (![removeArray containsObject:[package packageIdentifier]]) {
        [removeArray addObject:[package packageIdentifier]];
        [_managedQueue setObject:removeArray forKey:@"Remove"];
      }
      break;
    }
    case AUPMQueueActionReinstall: {
      NSMutableArray *reinstallArray = [_managedQueue[@"Reinstall"] mutableCopy];
      if (![reinstallArray containsObject:[package packageIdentifier]]) {
        [reinstallArray addObject:[package packageIdentifier]];
        [_managedQueue setObject:reinstallArray forKey:@"Reinstall"];
      }
      break;
    }
    case AUPMQueueActionUpgrade: {
      NSMutableArray *upgradeArray = [_managedQueue[@"Upgrade"] mutableCopy];
      if (![upgradeArray containsObject:[package packageIdentifier]]) {
        [upgradeArray addObject:[package packageIdentifier]];
        [_managedQueue setObject:upgradeArray forKey:@"Upgrade"];
      }
      break;
    }
  }
}

- (void)addPackages:(NSArray<AUPMPackage *> *)packages toQueueWithAction:(AUPMQueueAction)action {
  for (AUPMPackage *package in packages) {
    switch (action) {
      case AUPMQueueActionInstall: {
        NSMutableArray *installArray = [_managedQueue[@"Install"] mutableCopy];
        if (![installArray containsObject:[NSString stringWithFormat:@"%@=%@", [package packageIdentifier], [package version]]]) {
          [installArray addObject:[NSString stringWithFormat:@"%@=%@", [package packageIdentifier], [package version]]];
          [_managedQueue setObject:installArray forKey:@"Install"];
        }
        break;
      }
      case AUPMQueueActionRemove: {
        NSMutableArray *removeArray = [_managedQueue[@"Remove"] mutableCopy];
        if (![removeArray containsObject:[package packageIdentifier]]) {
          [removeArray addObject:[package packageIdentifier]];
          [_managedQueue setObject:removeArray forKey:@"Remove"];
        }
        break;
      }
      case AUPMQueueActionReinstall: {
        NSMutableArray *reinstallArray = [_managedQueue[@"Reinstall"] mutableCopy];
        if (![reinstallArray containsObject:[package packageIdentifier]]) {
          [reinstallArray addObject:[package packageIdentifier]];
          [_managedQueue setObject:reinstallArray forKey:@"Reinstall"];
        }
        break;
      }
      case AUPMQueueActionUpgrade: {
        NSMutableArray *upgradeArray = [_managedQueue[@"Upgrade"] mutableCopy];
        if (![upgradeArray containsObject:[package packageIdentifier]]) {
          [upgradeArray addObject:[package packageIdentifier]];
          [_managedQueue setObject:upgradeArray forKey:@"Upgrade"];
        }
        break;
      }
    }
  }
}

- (void)removePackage:(NSString *)packageIdentifier fromQueueWithAction:(AUPMQueueAction)action {
  switch (action) {
    case AUPMQueueActionInstall: {
      NSMutableArray *installArray = [_managedQueue[@"Install"] mutableCopy];
      [installArray removeObject:packageIdentifier];
      [_managedQueue setObject:installArray forKey:@"Install"];
      break;
    }
    case AUPMQueueActionRemove: {
      NSMutableArray *removeArray = [_managedQueue[@"Remove"] mutableCopy];
      [removeArray removeObject:packageIdentifier];
      [_managedQueue setObject:removeArray forKey:@"Remove"];
      break;
    }
    case AUPMQueueActionReinstall: {
      NSMutableArray *reinstallArray = [_managedQueue[@"Reinstall"] mutableCopy];
      [reinstallArray removeObject:packageIdentifier];
      [_managedQueue setObject:reinstallArray forKey:@"Reinstall"];
      break;
    }
    case AUPMQueueActionUpgrade: {
      NSMutableArray *upgradeArray = [_managedQueue[@"Upgrade"] mutableCopy];
      [upgradeArray removeObject:packageIdentifier];
      [_managedQueue setObject:upgradeArray forKey:@"Upgrade"];
      break;
    }
  }
}

- (NSArray *)tasksForQueue {
  NSMutableArray<NSMutableArray *> *commands = [NSMutableArray new];
  NSLog(@"[AUPM] Queue! %@", _managedQueue);
  NSArray *baseCommand = [[NSArray alloc] initWithObjects:@"apt-get", @"-o", @"Dir::Etc::SourceList=/var/lib/aupm/aupm.list", @"-o", @"Dir::State::Lists=/var/lib/aupm/lists", @"-o", @"Dir::Etc::SourceParts=/var/lib/aupm/lists/partial/false", @"-y", @"--force-yes", nil];

  NSMutableArray *installArray = [_managedQueue[@"Install"] mutableCopy];
  NSMutableArray *removeArray = [_managedQueue[@"Remove"] mutableCopy];
  NSMutableArray *reinstallArray = [_managedQueue[@"Reinstall"] mutableCopy];
  NSMutableArray *upgradeArray = [_managedQueue[@"Upgrade"] mutableCopy];

  if ([installArray count] > 0) {
    NSMutableArray *installCommand = [baseCommand mutableCopy];

    [installCommand insertObject:@"install" atIndex:1];
    for (NSString *package in installArray) {
      [installCommand insertObject:package atIndex:2]; //Needs to be in the format packageID=version
    }

    [commands addObject:installCommand];
  }

  if ([removeArray count] > 0) {
    NSMutableArray *removeCommand = [baseCommand mutableCopy];

    [removeCommand insertObject:@"remove" atIndex:1];
    for (NSString *package in removeArray) {
      [removeCommand insertObject:package atIndex:2];
    }

    [commands addObject:removeCommand];
  }

  if ([reinstallArray count] > 0) {
    NSMutableArray *reinstallCommand = [baseCommand mutableCopy];

    [reinstallCommand insertObject:@"install" atIndex:1];
    [reinstallCommand insertObject:@"--reinstall" atIndex:2];
    for (NSString *package in reinstallArray) {
      [reinstallCommand insertObject:package atIndex:3];
    }

    [commands addObject:reinstallCommand];
  }

  if ([upgradeArray count] > 0) {
    NSMutableArray *upgradeCommand = [baseCommand mutableCopy];

    [upgradeCommand insertObject:@"upgrade" atIndex:1];
    for (NSString *package in reinstallArray) {
      [upgradeCommand insertObject:package atIndex:2];
    }

    [commands addObject:upgradeCommand];
  }

  NSLog(@"[AUPM] Commands to run: %@", commands);
  return (NSArray *)commands;
}

- (int)numberOfPackagesForQueue:(NSString *)queue {
  return [_managedQueue[queue] count];
}

- (NSString *)packageInQueueForAction:(AUPMQueueAction)action atIndex:(int)index {
  switch (action) {
    case AUPMQueueActionInstall: {
      return [_managedQueue[@"Install"] objectAtIndex:index];
    }
    case AUPMQueueActionRemove: {
      return [_managedQueue[@"Remove"] objectAtIndex:index];
    }
    case AUPMQueueActionReinstall: {
      return [_managedQueue[@"Reinstall"] objectAtIndex:index];
    }
    case AUPMQueueActionUpgrade: {
      return [_managedQueue[@"Upgrade"] objectAtIndex:index];
    }
  }
}

- (void)clearQueue {
  _managedQueue = [NSMutableDictionary new];
  [_managedQueue setObject:@[] forKey:@"Install"];
  [_managedQueue setObject:@[] forKey:@"Remove"];
  [_managedQueue setObject:@[] forKey:@"Reinstall"];
  [_managedQueue setObject:@[] forKey:@"Upgrade"];
}

- (NSArray *)actionsToPerform {
  NSMutableArray *actions = [NSMutableArray new];
  if ([_managedQueue[@"Install"] count] > 0) {
    NSLog(@"Action is coming!");
    [actions addObject:@"Install"];
  }

  if ([_managedQueue[@"Remove"] count] > 0) {
    [actions addObject:@"Remove"];
  }

  if ([_managedQueue[@"Reinstall"] count] > 0) {
    [actions addObject:@"Reinstall"];
  }

  if ([_managedQueue[@"Upgrade"] count] > 0) {
    [actions addObject:@"Upgrade"];
  }

  NSLog(@"Action is coming! %@", actions);
  return (NSArray *)actions;
}
@end
