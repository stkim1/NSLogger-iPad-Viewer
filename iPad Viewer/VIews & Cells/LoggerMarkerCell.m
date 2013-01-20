//
//  LoggerMarkerCell.m
//  ipadnslogger
//
//  Created by Almighty Kim on 1/20/13.
//  Copyright (c) 2013 Colorful Glue. All rights reserved.
//

#import "LoggerMarkerCell.h"

NSString * const kMarkerCellReuseID = @"markerCell";

@implementation LoggerMarkerCell

-(id)initWithPreConfig
{
	return
		[self
		 initWithStyle:UITableViewCellStyleDefault
		 reuseIdentifier:kMarkerCellReuseID];
}

- (void)drawMessageView:(CGRect)aRect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	UIColor *backgroundColor = [UIColor yellowColor];
	
	[backgroundColor set];
	CGContextFillRect(context, aRect);
}

@end
