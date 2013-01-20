//
//  AppDelegate.h
//  LoggerStorage
//
//  Created by Almighty Kim on 12/16/12.
//  Copyright (c) 2012 Colorful Glue. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ViewController *viewController;
-(void)deletePath;
@end
