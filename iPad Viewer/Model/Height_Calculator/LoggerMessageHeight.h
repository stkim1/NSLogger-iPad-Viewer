//
//  LoggerMessageHeight.h
//  ipadnslogger
//
//  Created by Almighty Kim on 1/19/13.
//  Copyright (c) 2013 Colorful Glue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoggerConstModel.h"
#import "LoggerConstView.h"

@class LoggerMessage;

@interface LoggerMessageHeight : NSObject
+ (CGFloat)minimumHeightForCellOnWidth:(CGFloat)aWidth;

+ (CGFloat)heightForFileLineFunctionOnWidth:(CGFloat)aWidth;

+ (CGFloat)heightForMessage:(LoggerMessage *)aMessage
					onWidth:(CGFloat)aWidth;

+ (CGFloat)heightForFileLineFunctionOfMessage:(LoggerMessage *)aMessage
									  onWidth:(CGFloat)aWidth;
@end
