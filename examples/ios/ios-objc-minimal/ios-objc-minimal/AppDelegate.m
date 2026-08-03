#import "AppDelegate.h"

#import <ShenaiSDK/ShenaiSDK.h>
#import <ShenaiSDK/ShenaiView.h>
#import "CeConfig.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

  if ([CE_API_KEY length] == 0) {
    [self showMessage:@"Set SHENAI_API_KEY and run the example again."];
    return YES;
  }

  InitializationSettings *settings = [[InitializationSettings alloc] init];
  settings.initializationMode = Measurement;

  NSString *userId = [CE_USER_ID length] == 0 ? nil : CE_USER_ID;
  InitializationResult result = [ShenaiSDK initialize:CE_API_KEY userID:userId settings:settings];
  if (result != InitializationResultSuccess) {
    [self showMessage:[NSString stringWithFormat:@"Shen.AI initialization failed: %ld", (long)result]];
    return YES;
  }

  [ShenaiSDK setLanguage:CE_LANGUAGE];
  self.window.rootViewController = [[ShenaiView alloc] init];
  [self.window makeKeyAndVisible];
  return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
  [ShenaiSDK deinitialize];
}
- (void)showMessage:(NSString *)message {
  UIViewController *controller = [[UIViewController alloc] init];
  controller.view.backgroundColor = [UIColor systemBackgroundColor];

  UILabel *label = [[UILabel alloc] init];
  label.text = message;
  label.textAlignment = NSTextAlignmentCenter;
  label.numberOfLines = 0;
  label.translatesAutoresizingMaskIntoConstraints = NO;

  [controller.view addSubview:label];
  [NSLayoutConstraint activateConstraints:@[
    [label.leadingAnchor constraintEqualToAnchor:controller.view.leadingAnchor constant:24],
    [label.trailingAnchor constraintEqualToAnchor:controller.view.trailingAnchor constant:-24],
    [label.centerYAnchor constraintEqualToAnchor:controller.view.centerYAnchor],
  ]];

  self.window.rootViewController = controller;
  [self.window makeKeyAndVisible];
}

@end
