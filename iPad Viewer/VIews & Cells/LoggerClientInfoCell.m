//
//  LoggerClientInfoCell.m
//  ipadnslogger
//
//  Created by Almighty Kim on 1/20/13.
//  Copyright (c) 2013 Colorful Glue. All rights reserved.
//

#import "LoggerClientInfoCell.h"

NSString * const kClientInfoCellReuseID = @"clientInfoCell";

@implementation LoggerClientInfoCell

-(id)initWithPreConfig
{
	return
		[self
		 initWithStyle:UITableViewCellStyleDefault
		 reuseIdentifier:kClientInfoCellReuseID];
}

- (void)drawMessageView:(CGRect)aRect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	UIColor *backgroundColor = [UIColor redColor];

	//UIColor *textColor = [UIColor blackColor];
	[backgroundColor set];
	CGContextFillRect(context, aRect);
}

@end
