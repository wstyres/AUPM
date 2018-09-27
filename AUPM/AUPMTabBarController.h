@interface AUPMTabBarController : UITabBarController {
  NSArray *_updateObjects;
}
- (void)performBackgroundRefresh:(BOOL)requested;
- (NSArray *)updateObjects;
@end
