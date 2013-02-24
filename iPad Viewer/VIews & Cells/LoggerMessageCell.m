/*
 * LoggerMessageCell.m
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

#import "LoggerMessageCell.h"

NSString * const kMessageCellReuseID = @"messageCell";
UIFont *displayDefaultFont = nil;
UIFont *displayTagAndLevelFont = nil;
UIFont *displayMonospacedFont = nil;

UIColor *defaultBackgroundColor = nil;
UIColor *defaultTagAndLevelColor = nil;

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
	if(displayDefaultFont == nil)
	{
		displayDefaultFont =
			[[UIFont
			  fontWithName:kDefaultFontName
			  size:DEFAULT_FONT_SIZE] retain];
	}
	
	if(displayTagAndLevelFont == nil)
	{
		displayTagAndLevelFont =
			[[UIFont
			  fontWithName:kTagAndLevelFontName
			  size:DEFAULT_TAG_LEVEL_SIZE] retain];
	}
	
	if(displayMonospacedFont == nil)
	{
		displayMonospacedFont =
			[[UIFont
			  fontWithName:kMonospacedFontName
			  size:DEFAULT_MONOSPACED_SIZE] retain];
	}
	
	if(defaultBackgroundColor == nil)
	{
		defaultBackgroundColor =
			[[UIColor
			 colorWithRed:DEAFULT_BACKGROUND_GRAY_VALUE
			 green:DEAFULT_BACKGROUND_GRAY_VALUE
			 blue:DEAFULT_BACKGROUND_GRAY_VALUE
			 alpha:1] retain];
	}
	
	if(defaultTagAndLevelColor == nil)
	{
		defaultTagAndLevelColor =
			[[UIColor
			  colorWithRed:0.51f
			  green:0.57f
			  blue:0.79f
			  alpha:1.0f] retain];
	}
}

+ (UIColor *)colorForTag:(NSString *)tag
{
	// @@@ TODO: tag color customization mechanism
	return defaultTagAndLevelColor;
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

#if 0
- (void)setNeedsLayout
{
	[super setNeedsLayout];
	[_messageView setNeedsLayout];
}
#endif

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

-(void)setupForIndexpath:(NSIndexPath *)anIndexPath
			 messageData:(LoggerMessageData *)aMessageData
{
	_messageData = aMessageData;

	[aMessageData readMessageData:NULL];
	
	[self setNeedsDisplay];
}

//------------------------------------------------------------------------------
#pragma mark - Drawing
//------------------------------------------------------------------------------
- (void)drawTimestampAndDeltaInRect:(CGRect)aDrawRect
			   highlightedTextColor:(UIColor *)aHighlightedTextColor
{
	// Draw timestamp and time delta column
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);
	
	// set text color
	[[UIColor blackColor] set];

	CGContextClipToRect(context, aDrawRect);
	CGRect tr = CGRectInset(aDrawRect, 2, 0);
	
	// Prepare time delta between this message and the previous displayed (filtered) message

	struct timeval tv = int64totime([_messageData.timestamp unsignedLongLongValue]);

	//struct timeval td;

#ifdef USE_TM_COMPARISON
	if (previousMessage != nil)
		[message computeTimeDelta:&td since:previousMessage];
#endif

	time_t sec = tv.tv_sec;
	struct tm *t = localtime(&sec);

#warning CACHE_THIS_ITEM
	NSString *timestampStr;
	if (tv.tv_usec == 0)
		timestampStr = [NSString stringWithFormat:@"%02d:%02d:%02d", t->tm_hour, t->tm_min, t->tm_sec];
	else
		timestampStr = [NSString stringWithFormat:@"%02d:%02d:%02d.%03d", t->tm_hour, t->tm_min, t->tm_sec, tv.tv_usec / 1000];

#ifdef USE_TM_COMPARISON
	NSString *timeDeltaStr = nil;
	if (previousMessage != nil)
		timeDeltaStr = StringWithTimeDelta(&td);
#endif
	
#warning CACHE_THIS_ITEM
	CGSize bounds = [timestampStr
					 sizeWithFont:displayDefaultFont
					 forWidth:tr.size.width
					 lineBreakMode:NSLineBreakByWordWrapping];
	CGRect timeRect = CGRectMake(CGRectGetMinX(tr), CGRectGetMinY(tr), CGRectGetWidth(tr), bounds.height);
	//CGRect deltaRect = CGRectMake(CGRectGetMinY(tr), CGRectGetMaxY(timeRect)+1, CGRectGetWidth(tr), tr.size.height - bounds.height - 1);

/* will be added for ios6 support
	if (aHighlightedTextColor)
	{
		attrs = [[attrs mutableCopy] autorelease];
		[attrs setObject:highlightedTextColor forKey:NSForegroundColorAttributeName];
	}
*/
	[timestampStr
	 drawInRect:timeRect
	 withFont:displayDefaultFont
	 lineBreakMode:NSLineBreakByWordWrapping
	 alignment:NSTextAlignmentLeft];
/*
	attrs = [self timedeltaAttributes];
	if (highlightedTextColor)
	{
		attrs = [[attrs mutableCopy] autorelease];
		[attrs setObject:highlightedTextColor forKey:NSForegroundColorAttributeName];
	}
	[timeDeltaStr drawWithRect:deltaRect
					   options:NSStringDrawingUsesLineFragmentOrigin
					attributes:attrs];
*/

	CGContextRestoreGState(context);
}

- (void)drawThreadIDAndTagInRect:(CGRect)aDrawRect
			highlightedTextColor:(UIColor *)aHighlightedTextColor
{
	// Draw timestamp and time delta column
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);
	
	CGRect r = aDrawRect;
/*
	// Draw thread ID
	NSMutableDictionary *attrs = [self threadIDAttributes];
	if (aHighlightedTextColor != nil)
	{
		attrs = [[attrs mutableCopy] autorelease];
		[attrs setObject:highlightedTextColor forKey:NSForegroundColorAttributeName];
	}
*/

	CGContextClipToRect(context, r);
	
	CGSize threadBounds =
		[_messageData.threadID
		 sizeWithFont:displayDefaultFont
		 forWidth:r.size.width
		 lineBreakMode:NSLineBreakByWordWrapping];

	r.size.height = threadBounds.height;
	
	[[UIColor grayColor] set];

	[_messageData.threadID
	 drawInRect:CGRectInset(r, 3, 0)
	 withFont:displayDefaultFont
	 lineBreakMode:NSLineBreakByWordWrapping
	 alignment:NSTextAlignmentLeft];

	// Draw tag and level, if provided
	NSString *tag = _messageData.tag;
	int level = [_messageData.level intValue];
	if ([tag length] || level)
	{
		CGFloat threadColumnWidth = DEFAULT_THREAD_COLUMN_WIDTH;
		CGSize tagSize = CGSizeZero;
		CGSize levelSize = CGSizeZero;
		NSString *levelString = nil;
		r.origin.y += CGRectGetHeight(r);
		
		// set tag,level text color
		[[UIColor whiteColor] set];

		if ([tag length])
		{
			tagSize =
				[tag
				 sizeWithFont:displayTagAndLevelFont
				 forWidth:threadColumnWidth
				 lineBreakMode:NSLineBreakByWordWrapping];
			
			tagSize.width += 4;
			tagSize.height += 2;
		}
		
		if (level)
		{
			levelString = [NSString stringWithFormat:@"%d", level];
			
			levelSize =
				[levelString
				 sizeWithFont:displayTagAndLevelFont
				 forWidth:threadColumnWidth
				 lineBreakMode:NSLineBreakByWordWrapping];
			
			
			levelSize.width += 4;
			levelSize.height += 2;
		}
		
		CGFloat h = fmaxf(tagSize.height, levelSize.height);
		
		
		
		CGRect tagRect = CGRectMake(CGRectGetMinX(r) + 3,
									CGRectGetMinY(r),
									tagSize.width,h);

		CGRect levelRect = CGRectMake(CGRectGetMaxX(tagRect),
									  CGRectGetMinY(tagRect),
									  levelSize.width,h);

		CGRect tagAndLevelRect = CGRectUnion(tagRect, levelRect);
		
		MakeRoundedPath(context, tagAndLevelRect, 3.0f);
		CGColorRef fillColor = [[LoggerMessageCell colorForTag:tag] CGColor];
		CGContextSetFillColorWithColor(context, fillColor);
		CGContextFillPath(context);
		
		if (levelSize.width)
		{
			UIColor *black = GRAYCOLOR(0.25f);
			CGContextSaveGState(context);
			CGContextSetFillColorWithColor(context, [black CGColor]);
			CGContextClipToRect(context,levelRect);
			MakeRoundedPath(context, tagAndLevelRect, 3.0f);
			CGContextFillPath(context);
			CGContextRestoreGState(context);
		}

		// set text color
		[[UIColor whiteColor] set];
		
		if (tagSize.width)
		{
			[tag
			 drawInRect:CGRectInset(tagRect, 2, 1)
			 withFont:displayTagAndLevelFont
			 lineBreakMode:NSLineBreakByWordWrapping
			 alignment:NSTextAlignmentLeft];
		}

		if (levelSize.width)
		{
			[levelString
			 drawInRect:CGRectInset(levelRect, 2, 1)
			 withFont:displayTagAndLevelFont
			 lineBreakMode:NSLineBreakByWordWrapping
			 alignment:NSTextAlignmentRight];
		}
	}

	CGContextRestoreGState(context);
}


- (void)drawMessageInRect:(CGRect)aDrawRect
	 highlightedTextColor:(UIColor *)aHighlightedTextColor
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);

	[[UIColor blackColor] set];

	UIFont *monospacedFont = displayMonospacedFont;
	
	switch([_messageData.contentsType shortValue])
	{
		case kMessageString:{
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
						 sizeWithFont:monospacedFont
						 forWidth:MSG_CELL_PORTRAIT_WIDTH
						 lineBreakMode:NSLineBreakByWordWrapping];
			
			if (lr.height > aDrawRect.size.height)
				truncated = YES;
			else
			{
				aDrawRect.origin.y += floorf((aDrawRect.size.height - lr.height) / 2.0f);
				aDrawRect.size.height = lr.height;
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
					 sizeWithFont:monospacedFont
					 constrainedToSize:aDrawRect.size
					 lineBreakMode:NSLineBreakByWordWrapping].height;
			}
			
			aDrawRect.size.height -= hintHeight;
			[s
			 drawInRect:aDrawRect
			 withFont:monospacedFont
			 lineBreakMode:NSLineBreakByWordWrapping
			 alignment:NSTextAlignmentLeft];
			
			
			// Draw hint "Double click to see all text..." if needed
			if (hint != nil)
			{
				aDrawRect.origin.y += aDrawRect.size.height;
				aDrawRect.size.height = hintHeight;
				[hint
				 drawInRect:aDrawRect
				 withFont:monospacedFont
				 lineBreakMode:NSLineBreakByWordWrapping
				 alignment:NSTextAlignmentLeft];
			}

			break;
		}
		case kMessageData: {
			NSString *s = [_messageData textRepresentation];
			[s
			 drawInRect:aDrawRect
			 withFont:monospacedFont
			 lineBreakMode:NSLineBreakByWordWrapping
			 alignment:NSTextAlignmentLeft];

			break;
		}
		case kMessageImage: {
		// do nothing yet
		}
	}
	
	CGContextRestoreGState(context);

}

- (void)drawMessageView:(CGRect)cellFrame
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);
	
	// turn antialiasing off
	CGContextSetShouldAntialias(context, false);

	//fill background with generic gray in value of 0.97f
	UIColor *backgroundColor = defaultBackgroundColor;
	[backgroundColor set];
	CGContextFillRect(context, cellFrame);
	
	
	// Draw separators
	CGContextSetLineWidth(context, 1.0f);
	CGContextSetLineCap(context, kCGLineCapSquare);
	UIColor *cellSeparatorColor = GRAYCOLOR(0.8f);
#if 0
	if (highlighted)
		cellSeparatorColor = CGColorCreateGenericGray(1.0f, 1.0f);
	else
		cellSeparatorColor = CGColorCreateGenericGray(0.80f, 1.0f);
#endif

	CGContextSetStrokeColorWithColor(context, [cellSeparatorColor CGColor]);
	CGContextBeginPath(context);
	
	// timestamp/thread separator
	CGContextMoveToPoint(context, floorf(CGRectGetMinX(cellFrame) + TIMESTAMP_COLUMN_WIDTH), CGRectGetMinY(cellFrame));
	CGContextAddLineToPoint(context, floorf(CGRectGetMinX(cellFrame) + TIMESTAMP_COLUMN_WIDTH), floorf(CGRectGetMaxY(cellFrame)-1));
	
	// thread/message separator
	CGFloat threadColumnWidth = DEFAULT_THREAD_COLUMN_WIDTH;
	
	CGContextMoveToPoint(context, floorf(CGRectGetMinX(cellFrame) + TIMESTAMP_COLUMN_WIDTH + threadColumnWidth), CGRectGetMinY(cellFrame));
	CGContextAddLineToPoint(context, floorf(CGRectGetMinX(cellFrame) + TIMESTAMP_COLUMN_WIDTH + threadColumnWidth), floorf(CGRectGetMaxY(cellFrame)-1));
	CGContextStrokePath(context);
    
	// restore antialiasing
	CGContextSetShouldAntialias(context, true);
	
	
	// Draw timestamp and time delta column
	CGRect drawRect = CGRectMake(CGRectGetMinX(cellFrame),
						  CGRectGetMinY(cellFrame),
						  TIMESTAMP_COLUMN_WIDTH,
						  CGRectGetHeight(cellFrame));

	[self drawTimestampAndDeltaInRect:drawRect highlightedTextColor:nil];
	
	// Draw thread ID and tag
	drawRect = CGRectMake(CGRectGetMinX(cellFrame) + TIMESTAMP_COLUMN_WIDTH,
				   CGRectGetMinY(cellFrame),
				   DEFAULT_THREAD_COLUMN_WIDTH,
				   CGRectGetHeight(cellFrame));

	[self drawThreadIDAndTagInRect:drawRect highlightedTextColor:nil];
	
	
	
	// Draw message
	drawRect = CGRectMake(CGRectGetMinX(cellFrame) + TIMESTAMP_COLUMN_WIDTH + DEFAULT_THREAD_COLUMN_WIDTH + 3,
				   CGRectGetMinY(cellFrame),
				   CGRectGetWidth(cellFrame) - (TIMESTAMP_COLUMN_WIDTH + DEFAULT_THREAD_COLUMN_WIDTH) - 6,
				   CGRectGetHeight(cellFrame));
	CGFloat fileLineFunctionHeight = 0;
	
	[self drawMessageInRect:drawRect highlightedTextColor:nil];
	
	
	CGContextRestoreGState(context);
}
@end
