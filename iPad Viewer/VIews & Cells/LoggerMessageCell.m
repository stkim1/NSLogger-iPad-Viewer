//
//  LoggerMessageCell.m
//  ipadnslogger
//
//  Created by Almighty Kim on 1/18/13.
//  Copyright (c) 2013 Colorful Glue. All rights reserved.
//

#import "LoggerMessageCell.h"

NSString * const kMessageCellReuseID = @"messageCell";

UIFont *sDisplayFont = nil;

@interface LoggerMessageView : UIView
@end
@implementation LoggerMessageView
- (void)drawRect:(CGRect)aRect
{
	[(LoggerMessageCell *)[self superview] drawMessageView:aRect];
}
@end

@implementation LoggerMessageCell
@synthesize messageData = _messageData;

+(void)initialize
{
	if(sDisplayFont == nil)
	{
		sDisplayFont = [[UIFont systemFontOfSize:DEFAULT_FONT_SIZE] retain];
	}
}

-(id)initWithPreConfig
{
	return
		[self
		 initWithStyle:UITableViewCellStyleDefault
		 reuseIdentifier:kMessageCellReuseID];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
	{
		self.accessoryType = UITableViewCellAccessoryNone;
		_messageView = [[LoggerMessageView alloc] initWithFrame:CGRectZero];
		_messageView.opaque = YES;
		[self addSubview:_messageView];
		[_messageView release];
    }
    return self;
}

-(void)dealloc
{
	_messageData = nil;
	self.hostTableView = nil;
	[super dealloc];
}

- (void)setFrame:(CGRect)aFrame
{
	[super setFrame:aFrame];
	CGRect bound = [self bounds];

	// leave room for the seperator line
	CGRect messageFrame = CGRectInset(bound, 0, 1);

	[_messageView setFrame:messageFrame];
}

- (void)setNeedsDisplay
{
	[super setNeedsDisplay];
	[_messageView setNeedsDisplay];
}

- (void)drawMessageView:(CGRect)aRect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	UIColor *backgroundColor = [UIColor whiteColor];

	UIColor *textColor = [UIColor blackColor];
	[backgroundColor set];
	CGContextFillRect(context, aRect);
	
	[textColor set];
	CGRect r = aRect;
	
	if (_messageData.contentsType == kMessageString)
	{
		
		MTLog(@"draw text messages");
		
		// in case the message text is empty, use the function name as message text
		// this is typically used to record a waypoint in the code flow
		NSString *s = _messageData.messageText;
		if (![s length] && _messageData.functionName)
			s = _messageData.functionName;
		
		// very long messages can't be displayed entirely. No need to compute their full size,
		// it slows down the UI to no avail. Just cut the string to a reasonable size, and take
		// the calculations from here.
		BOOL truncated = NO;
		if ([s length] > 2048)
		{
			truncated = YES;
			s = [s substringToIndex:2048];
		}
		
		// compute display string size, limit to cell height
		CGSize lr = [s
					 sizeWithFont:sDisplayFont
					 forWidth:MSG_CELL_PORTRAIT_WIDTH
					 lineBreakMode:NSLineBreakByWordWrapping];
		
		if (lr.height > r.size.height)
			truncated = YES;
		else
		{
			r.origin.y += floorf((r.size.height - lr.height) / 2.0f);
			r.size.height = lr.height;
		}
		
		CGFloat hintHeight = 0;
		NSString *hint = nil;
		if (truncated)
		{
			// display a hint instructing user to double-click message in order
			// to see all contents
			
			hint = NSLocalizedString(@"Double-click to see all text...", @"");
			hintHeight =
				[hint
				 sizeWithFont:sDisplayFont
				 constrainedToSize:r.size
				 lineBreakMode:NSLineBreakByWordWrapping].height;
		}
		
		r.size.height -= hintHeight;
		[s
		 drawInRect:r
		 withFont:sDisplayFont
		 lineBreakMode:NSLineBreakByWordWrapping
		 alignment:NSTextAlignmentLeft];
		
		
		// Draw hint "Double click to see all text..." if needed
		if (hint != nil)
		{
			r.origin.y += r.size.height;
			r.size.height = hintHeight;
			[hint
			 drawInRect:r
			 withFont:sDisplayFont
			 lineBreakMode:NSLineBreakByWordWrapping
			 alignment:NSTextAlignmentLeft];
		}
	}
	else if (_messageData.contentsType == kMessageData)
	{
		NSString *s = [_messageData textRepresentation];
		[s
		 drawInRect:r
		 withFont:sDisplayFont
		 lineBreakMode:NSLineBreakByWordWrapping
		 alignment:NSTextAlignmentLeft];
		
	}
	else if (_messageData.contentsType == kMessageImage)
	{
		// do nothing yet
	}
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

-(void)setupForIndexpath:(NSIndexPath *)anIndexPath
			 messageData:(LoggerMessageData *)aMessageData
{
	_messageData = aMessageData;
	[self.textLabel setText:_messageData.threadID];
}

@end
