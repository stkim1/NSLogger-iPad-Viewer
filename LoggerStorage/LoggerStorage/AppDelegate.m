//
//  AppDelegate.m
//  LoggerStorage
//
//  Created by Almighty Kim on 12/16/12.
//  Copyright (c) 2012 Colorful Glue. All rights reserved.
//

#import "AppDelegate.h"

#import "ViewController.h"
#import "LoggerDataStorage.h"
#import "LoggerClient.h"
#import <mach/mach_time.h>

@interface AppDelegate()
@property (nonatomic, retain) LoggerDataStorage *storage;
@property (nonatomic, retain) NSMutableArray *images;
@end

@implementation AppDelegate
@synthesize storage;
@synthesize images;

#define kOperationQueue 10
#define kPauseCount 2

- (void)dealloc
{
	[_window release];
	[_viewController release];
    [super dealloc];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// This method ensures that a different image is created from block of data
    UIImage* buddyJesus = [UIImage imageNamed:@"buddy_jesus.jpg"];
	
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:kOperationQueue];
    for (NSUInteger i = 0; i < kOperationQueue; i++) {
		NSData* imageData = UIImagePNGRepresentation(buddyJesus);
        [array addObject:imageData];
    }
	
	[self setImages:array];
	
	LoggerDataStorage	*datastorage  = [[LoggerDataStorage alloc] init];
	[self setStorage:datastorage];
	[storage release];
	
	
	LoggerSetViewerHost(NULL, NULL, 0);
	LoggerSetOptions(NULL,
					 kLoggerOption_BufferLogsUntilConnection |
					 kLoggerOption_UseSSL |
					 kLoggerOption_BrowseBonjour| 0);
	
	
	
	
	
	
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
	self.viewController = [[[ViewController alloc] initWithNibName:@"ViewController" bundle:nil] autorelease];
	self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
	
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	NSLog(@"%@",[self testCacheAsyncness:[self storage]]);
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (NSString* )testCacheAsyncness:(LoggerDataStorage *)cache
{
	for (NSUInteger i = 0; i < kOperationQueue; i++)
	{
		[cache
		 writeData:[self.images objectAtIndex:i]
		 toPath:[NSString stringWithFormat:@"mindcontrol/file-%d.jpg",i]];


#if 1
		if( !(i%kPauseCount) )
		{
			[cache
			 readDataFromPath:@"mindcontrol/file-0.jpg"
			 forResult:^(NSData *aData) {
			 }];
		}
#endif
	}

	return @"";
}
-(void)deletePath
{
	NSLog(@"deletePath");
	[[self storage] deleteWholePath:@"mindcontrol"];
}

@end
