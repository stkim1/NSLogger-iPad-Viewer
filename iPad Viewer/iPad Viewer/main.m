//
//  main.m
//  ipadnslogger
//
//  Created by Almighty Kim on 10/26/12.
//  Copyright (c) 2012 Colorful Glue. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"
#import "LoggerTransportManager.h"
#import "LoggerPreferenceManager.h"
#import "LoggerDataManager.h"

int main(int argc, char *argv[])
{
    @autoreleasepool {

		LoggerDataManager *dataManager = [LoggerDataManager sharedDataManager];
		LoggerPreferenceManager *prefManager = [LoggerPreferenceManager sharedPrefManager];
		LoggerTransportManager *transportManager = [LoggerTransportManager sharedTransportManager];
		[transportManager setPrefManager:prefManager];
		[transportManager setDataManager:dataManager];

        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
