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
      [installArray addObject:[NSString stringWithFormat:@"%@=%@", [package packageIdentifier], [package version]]];
      [_managedQueue setObject:installArray forKey:@"install"];
      break;
    }
    case AUPMQueueActionRemove: {
      NSMutableArray *removeArray = [_managedQueue[@"remove"] mutableCopy];
      [removeArray addObject:[package packageIdentifier]];
      [_managedQueue setObject:removeArray forKey:@"remove"];
      break;
    }
    case AUPMQueueActionReinstall: {
      NSMutableArray *reinstallArray = [_managedQueue[@"reinstall"] mutableCopy];
      [reinstallArray addObject:[package packageIdentifier]];
      [_managedQueue setObject:reinstallArray forKey:@"reinstall"];
      break;
    }
    case AUPMQueueActionUpgrade: {
      NSMutableArray *upgradeArray = [_managedQueue[@"upgrade"] mutableCopy];
      [upgradeArray addObject:[package packageIdentifier]];
      [_managedQueue setObject:upgradeArray forKey:@"upgrade"];
      break;
    }
  }
}

- (void)addPackages:(NSArray<AUPMPackage *> *)packages toQueueWithAction:(AUPMQueueAction)action {
  for (AUPMPackage *package in packages) {
    switch (action) {
      case AUPMQueueActionInstall: {
        NSMutableArray *installArray = [_managedQueue[@"install"] mutableCopy];
        [installArray addObject:[NSString stringWithFormat:@"%@=%@", [package packageIdentifier], [package version]]];
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

- (NSArray *)tasksForQueue {
  NSMutableArray<NSMutableArray *> *commands = [NSMutableArray new];
  NSLog(@"[AUPM] Queue! %@", _managedQueue);
  NSArray *baseCommand = [[NSArray alloc] initWithObjects:@"apt-get", @"-o", @"Dir::Etc::SourceList=/var/lib/aupm/aupm.list", @"-o", @"Dir::State::Lists=/var/lib/aupm/lists", @"-o", @"Dir::Etc::SourceParts=/var/lib/aupm/lists/partial/false", @"-y", @"--force-yes", nil];

  NSMutableArray *installArray = [_managedQueue[@"install"] mutableCopy];
  NSMutableArray *removeArray = [_managedQueue[@"remove"] mutableCopy];
  NSMutableArray *reinstallArray = [_managedQueue[@"reinstall"] mutableCopy];
  NSMutableArray *upgradeArray = [_managedQueue[@"upgrade"] mutableCopy];

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
      return [_managedQueue[@"install"] objectAtIndex:index];
    }
    case AUPMQueueActionRemove: {
      return [_managedQueue[@"remove"] objectAtIndex:index];
    }
    case AUPMQueueActionReinstall: {
      return [_managedQueue[@"reinstall"] objectAtIndex:index];
    }
    case AUPMQueueActionUpgrade: {
      return [_managedQueue[@"upgrade"] objectAtIndex:index];
    }
  }
}

- (void)clearQueue {
  _managedQueue = [NSMutableDictionary new];
  [_managedQueue setObject:@[] forKey:@"install"];
  [_managedQueue setObject:@[] forKey:@"remove"];
  [_managedQueue setObject:@[] forKey:@"reinstall"];
  [_managedQueue setObject:@[] forKey:@"upgrade"];
}
@end
