//
//  LoggerMessageCell.h
//  ipadnslogger
//
//  Created by Almighty Kim on 1/18/13.
//  Copyright (c) 2013 Colorful Glue. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoggerMessageData.h"
#import "LoggerConstView.h"

extern NSString * const kMessageCellReuseID;
extern UIFont *sDisplayFont;

@interface LoggerMessageCell : UITableViewCell
{
	UIView					*_messageView;		// a view which draws content of message
	UITableView				*_hostTableView;	// a tableview hosting this cell
	LoggerMessageData		*_messageData;		// *NOT RETAINED* : this comes from CoreData
}
@property (nonatomic, assign) UITableView				*hostTableView;
@property (nonatomic, readonly) LoggerMessageData		*messageData;

// initialize with predefined style and reuse identifier
-(id)initWithPreConfig;

// this method actually draws message content. subclasses should draw their own
-(void)drawMessageView:(CGRect)aRect;
-(void)setupForIndexpath:(NSIndexPath *)anIndexPath
			 messageData:(LoggerMessageData *)aMessageData;
@end
