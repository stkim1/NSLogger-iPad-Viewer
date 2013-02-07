/*
 * LoggerMessageCell.h
 *
 * BSD license follows (http://www.opensource.org/licenses/bsd-license.php)
 * 
 * Based on source code 
 * Copyright (c) 2010-2011 Florent Pillet <fpillet@gmail.com>
 * Copyright (c) 2008 Loren Brichter
 * Copyright (c) 2012-2013 Sung-Taek, Kim <stkim1@colorfulglue.com>
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * Redistributions of  source code  must retain  the above  copyright notice,
 * this list of  conditions and the following  disclaimer. Redistributions in
 * binary  form must  reproduce  the  above copyright  notice,  this list  of
 * conditions and the following disclaimer  in the documentation and/or other
 * materials  provided with  the distribution.  Neither the  name of  Sung-Ta
 * ek kim nor the names of its contributors may be used to endorse or promote
 * products  derived  from  this  software  without  specific  prior  written
 * permission.  THIS  SOFTWARE  IS  PROVIDED BY  THE  COPYRIGHT  HOLDERS  AND
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT
 * NOT LIMITED TO, THE IMPLIED  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A  PARTICULAR PURPOSE  ARE DISCLAIMED.  IN  NO EVENT  SHALL THE  COPYRIGHT
 * HOLDER OR  CONTRIBUTORS BE  LIABLE FOR  ANY DIRECT,  INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY,  OR CONSEQUENTIAL DAMAGES (INCLUDING,  BUT NOT LIMITED
 * TO, PROCUREMENT  OF SUBSTITUTE GOODS  OR SERVICES;  LOSS OF USE,  DATA, OR
 * PROFITS; OR  BUSINESS INTERRUPTION)  HOWEVER CAUSED AND  ON ANY  THEORY OF
 * LIABILITY,  WHETHER  IN CONTRACT,  STRICT  LIABILITY,  OR TORT  (INCLUDING
 * NEGLIGENCE  OR OTHERWISE)  ARISING  IN ANY  WAY  OUT OF  THE  USE OF  THIS
 * SOFTWARE,   EVEN  IF   ADVISED  OF   THE  POSSIBILITY   OF  SUCH   DAMAGE.
 *
 */

#import <UIKit/UIKit.h>
#import "LoggerMessageData.h"
#import "LoggerConstView.h"

extern NSString * const kMessageCellReuseID;

@interface LoggerMessageCell : UITableViewCell
{
	UIView					*_messageView;		// a view which draws content of message
	UITableView				*_hostTableView;	// a tableview hosting this cell
	LoggerMessageData		*_messageData;		// *NOT RETAINED* : this comes from CoreData

#ifdef TEST_CELL_INDEXPATH
	NSIndexPath				*_indexPath;
#endif
}
@property (nonatomic, assign) UITableView				*hostTableView;
@property (nonatomic, readonly) LoggerMessageData		*messageData;

// initialize with predefined style and reuse identifier
-(id)initWithPreConfig;

// this method actually draws message content. subclasses should draw their own
-(void)drawMessageView:(CGRect)aRect;
-(void)setupForIndexpath:(NSIndexPath *)anIndexPath
			 messageData:(LoggerMessageData *)aMessageData;

#ifdef TEST_CELL_INDEXPATH
-(void)willDisplayForIndexPath:(NSIndexPath *)anIndexPath
				   messageData:(LoggerMessageData *)aMessageData;
#endif
@end
