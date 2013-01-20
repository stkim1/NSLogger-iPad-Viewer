//
//  LoggerTransportManager.h
//  ipadnslogger
//
//  Created by Almighty Kim on 11/5/12.
//  Copyright (c) 2012 Colorful Glue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoggerPreferenceManager.h"
#import "LoggerTransport.h"
#import "LoggerConnection.h"
#import "LoggerDataManager.h"

@interface LoggerTransportManager : NSObject <LoggerTransportDelegate>
@property (nonatomic, retain) LoggerPreferenceManager		*prefManager;
@property (nonatomic, assign) LoggerDataManager				*dataManager;
+ (LoggerTransportManager *)sharedTransportManager;

- (void)createTransports;
- (void)destoryTransports;
- (void)startStopTransports;

- (void)reportTransportError:(NSError *)anError;
@end
