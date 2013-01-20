//
//  LoggerMarkerHeight.m
//  ipadnslogger
//
//  Created by Almighty Kim on 1/19/13.
//  Copyright (c) 2013 Colorful Glue. All rights reserved.
//

#import "LoggerMarkerHeight.h"
#import "LoggerMessage.h"

@implementation LoggerMarkerHeight
+ (CGFloat)heightForMessage:(LoggerMessage *)aMessage onWidth:(CGFloat)aWidth
{
	CGFloat minimumHeight = \
		[LoggerMessageHeight
		 minimumHeightForCellOnWidth:aWidth];
	
	UIFont *defaultSizedFont = \
		[UIFont systemFontOfSize:DEFAULT_FONT_SIZE];
	
	CGSize sz = CGSizeMake(aWidth, minimumHeight);
	
	sz.width -= 8;
	sz.height -= 4;
	
	CGSize lr = [aMessage.message
				 sizeWithFont:defaultSizedFont
				 forWidth:aWidth
				 lineBreakMode:NSLineBreakByWordWrapping];
	
	return fminf(lr.height, sz.height);
}

@end
