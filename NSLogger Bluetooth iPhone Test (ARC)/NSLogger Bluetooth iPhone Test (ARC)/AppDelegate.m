//
//  AppDelegate.m
//  NSLogger Bluetooth iPhone Test (ARC)
//
//  Created by Almighty Kim on 4/21/13.
//  Copyright (c) 2013 Colorful Glue. All rights reserved.
//

#import "AppDelegate.h"

#import "ViewController.h"
#import "LoggerBluetoothBrowserClient.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
	self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
	self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	stop_browsing();
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	start_browsing(true);
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

@end
