//
//  LoggerPreferenceManager.h
//  ipadnslogger
//
//  Created by Almighty Kim on 11/5/12.
//  Copyright (c) 2012 Colorful Glue. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LoggerPreferenceManager : NSObject
+(LoggerPreferenceManager *)sharedPrefManager;
@property (nonatomic, readonly) BOOL		shouldPublishBonjourService;
@property (nonatomic, readonly) BOOL		hasDirectTCPIPResponder;
@property (nonatomic, readonly) NSInteger	directTCPIPResponderPort;
@property (nonatomic, readonly) NSString	*bonjourServiceName;
@end
