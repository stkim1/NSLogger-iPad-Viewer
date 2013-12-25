/*
 *
 * Modified BSD license.
 *
 * Based on
 * Copyright (c) 2010-2011 Florent Pillet <fpillet@gmail.com>
 * Copyright (c) 2008 Loren Brichter,
 *
 * Copyright (c) 2012-2013 Sung-Taek, Kim <stkim1@colorfulglue.com> All Rights
 * Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Any redistribution is done solely for personal benefit and not for any
 *    commercial purpose or for monetary gain
 *
 * 4. No binary form of source code is submitted to App Store℠ of Apple Inc.
 *
 * 5. Neither the name of the Sung-Taek, Kim nor the names of its contributors
 *    may be used to endorse or promote products derived from  this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL COPYRIGHT HOLDER AND AND CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import "LoggerMessageCell.h"


NSString * const kMessageCellReuseID = @"messageCell";
UIFont *displayDefaultFont = nil;
UIFont *displayTagAndLevelFont = nil;
UIFont *displayMonospacedFont = nil;

UIColor *defaultBackgroundColor = nil;
UIColor *defaultTagAndLevelColor = nil;

NSString *defaultTextHint = nil;
NSString *defaultDataHint = nil;

//#define USE_UIKIT_FOR_DRAWING
//#define DEBUG_CT_STR_RANGE
//#define DEBUG_DRAW_AREA

@interface LoggerMessageView : UIView
@end
@implementation LoggerMessageView
- (void)drawRect:(CGRect)aRect
{
	[(LoggerMessageCell *)[[self superview] superview] drawMessageView:aRect];
}
@end

@implementation LoggerMessageCell
{
	CFMutableAttributedStringRef _displayString;
	CTFramesetterRef _textFrameSetter;
	CFMutableArrayRef _textFrameContainer;
}
@synthesize hostTableView = _hostTableView;
@synthesize messageData = _messageData;
@synthesize imageData = _imageData;
@synthesize displayString = _displayString;
@synthesize textFrameSetter = _textFrameSetter;
@synthesize textFrameContainer = _textFrameContainer;

+(void)initialize
{
	defaultTextHint = [NSLocalizedString(@"Double-click to see all text...", nil) retain];

	defaultDataHint = [NSLocalizedString(@"Double-click to see all data...", nil) retain];

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
		
		//@@TODO:: measure performance with this
		_messageView.opaque = YES;
		_messageView.clearsContextBeforeDrawing = NO;
		[self addSubview:_messageView];
		[_messageView release];
		
		
		//@@TODO :: check if memory is properly released, retained
		CFMutableArrayRef frameContainer = CFArrayCreateMutable(kCFAllocatorDefault,0, &kCFTypeArrayCallBacks );
		self.textFrameContainer = frameContainer;
		CFRelease(frameContainer);
		
    }
    return self;
}

-(void)dealloc
{
	self.hostTableView = nil;
	self.messageData = nil;
	self.imageData = nil;
	self.displayString = nil;
	self.textFrameSetter = nil;
	CFArrayRemoveAllValues(self.textFrameContainer);
	self.textFrameContainer = nil;

	[super dealloc];
}

- (void)setFrame:(CGRect)aFrame
{
	[super setFrame:aFrame];
	CGRect bound = [self bounds];

	// leave room for the seperator line
	//CGRect messageFrame = CGRectInset(bound, 0, 1);

	[_messageView setFrame:bound];
}

- (void)setNeedsDisplay
{
	[super setNeedsDisplay];
	[_messageView setNeedsDisplay];
}

- (void)setNeedsDisplayInRect:(CGRect)rect
{
	[super setNeedsDisplayInRect:rect];
	[_messageView setNeedsDisplayInRect:rect];
}


#if 0
- (void)setNeedsLayout
{
	[super setNeedsLayout];
	[_messageView setNeedsLayout];
}
#endif

-(void)prepareForReuse
{
	[super prepareForReuse];

	if([self.messageData dataType] == kMessageImage)
	{
		[self.messageData cancelImageForCell:self];
	}

	self.imageData = nil;
	self.messageData = nil;
	self.displayString = nil;
	self.textFrameSetter = nil;
	CFArrayRemoveAllValues(self.textFrameContainer);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

-(void)setupForIndexpath:(NSIndexPath *)anIndexPath
			 messageData:(LoggerMessageData *)aMessageData
{
	self.messageData = aMessageData;
	self.imageData = nil;

	if([aMessageData dataType] == kMessageImage)
	{
		[aMessageData imageForCell:self];
	}
	
	
	if(aMessageData != nil)
	{
		BOOL truncated = [[aMessageData truncated] boolValue];
		
		int totalTextLength = 0;
		int locTimestamp	= 0;
		
		//@@TODO:: timedelta
		int locTimedelta	= locTimestamp;// + [aMessageData.timedelta length];
		
		int locThread		= locTimedelta + [aMessageData.timestampString length];
		int locTag			= locThread + [aMessageData.threadID length];
		int locLevel		= locTag + [aMessageData.tag length];
		int locFileFunc		= locLevel + [[aMessageData.level stringValue] length];
		int locMessage		= locFileFunc + (IS_NULL_STRING(aMessageData.fileFuncRepresentation)?0:[aMessageData.fileFuncRepresentation length]);
		int locHint			= 0;

		switch([self.messageData dataType]){
			case kMessageString:{
				locHint = locMessage + [aMessageData.textRepresentation length];
				
				if(truncated){
					totalTextLength = locHint + [defaultTextHint length];
				}else{
					totalTextLength = locHint;
				}
				break;
			}
			case kMessageData: {
				locHint = locMessage + [aMessageData.textRepresentation length];
				
				if(truncated){
					totalTextLength = locHint + [defaultDataHint length];
				}else{
					totalTextLength = locHint;
				}
				break;
			}
			default:
				break;
		}
		
		//  Create an empty mutable string big enough to hold our test
		CFMutableAttributedStringRef as = CFAttributedStringCreateMutable(kCFAllocatorDefault, totalTextLength);
		CFAttributedStringBeginEditing(as);
		
		// Place timestamp string
		CFAttributedStringReplaceString(as, CFRangeMake(locTimestamp, 0), (CFStringRef)aMessageData.timestampString);
		
		// Place thread id string
		CFAttributedStringReplaceString(as, CFRangeMake(locThread, 0), (CFStringRef)aMessageData.threadID);
		
		// Place Tag
		CFAttributedStringReplaceString(as, CFRangeMake(locTag, 0), (CFStringRef)aMessageData.tag);
		
		// Place level
		CFAttributedStringReplaceString(as, CFRangeMake(locLevel, 0), (CFStringRef)[aMessageData.level stringValue]);
		
		// Place File, Func
		if(!IS_NULL_STRING(aMessageData.fileFuncRepresentation)){
			CFAttributedStringReplaceString(as, CFRangeMake(locFileFunc, 0), (CFStringRef)aMessageData.fileFuncRepresentation);
		}
		
		switch([self.messageData dataType]){
			case kMessageString:{
				CFAttributedStringReplaceString(as,CFRangeMake(locMessage, 0),(CFStringRef)aMessageData.textRepresentation);
				
				if(truncated){
					CFAttributedStringReplaceString(as,CFRangeMake(locHint, 0),(CFStringRef)defaultTextHint);
				}
				break;
			}
			case kMessageData: {
				CFAttributedStringReplaceString(as,CFRangeMake(locMessage, 0),(CFStringRef)aMessageData.textRepresentation);
				
				if(truncated){
					CFAttributedStringReplaceString(as,CFRangeMake(locHint, 0),(CFStringRef)defaultDataHint);
				}
				break;
			}
			default:
				break;
		}
		
		
		CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(as);
		self.textFrameSetter = framesetter;
		CFRelease(framesetter);
		
		CGRect cellFrame = self.bounds;

#ifdef DEBUG_DRAW_AREA
		MTLog(@"cellFrame %@",NSStringFromCGRect(cellFrame));
#endif
		
		//timestamp and delta
		CGRect drawRect = [self timestampAndDeltaFrame:cellFrame];
		CTFrameRef frame = \
			[self
			 timestampAndDeltaTextInRect:drawRect
			 stringForRect:as
			 timestampRange:CFRangeMake(0, abs(locThread - locTimestamp))
			 deltaRange:CFRangeMake(0, abs(locThread - locTimestamp))
			 frameSetter:framesetter];
			 
		CFArrayAppendValue(self.textFrameContainer,frame);
		CFRelease(frame);

		//thread id & tag
		drawRect = [self threadIDAndTagTextInRect:cellFrame];
		frame = \
			[self
			 threadIDAndTagTextInRect:drawRect
			 stringForRect:as
			 threadRange:CFRangeMake(locThread, [aMessageData.threadID length])
			 tagRange:CFRangeMake(locTag, [aMessageData.tag length])
			 levelRange:CFRangeMake(locLevel, [[aMessageData.level stringValue] length])
			 frameSetter:framesetter];
		
		CFArrayAppendValue(self.textFrameContainer,frame);
		CFRelease(frame);

		//file and function
		if(!IS_NULL_STRING(aMessageData.fileFuncRepresentation)  && false )
		{
			
			drawRect = [self fileLineFunctionTextInRect:cellFrame];
			frame = \
				[self
				 fileLineFunctionTextInRect:drawRect
				 stringForRect:as
				 stringRange:CFRangeMake(locFileFunc, [aMessageData.fileFuncRepresentation length])
				 frameSetter:framesetter];
			
			CFArrayAppendValue(self.textFrameContainer,frame);
			CFRelease(frame);
		}

		//message
		if([self.messageData dataType] != kMessageImage)
		{
			drawRect = [self messageTextInRect:cellFrame];
			frame = \
				[self
				 messageTextInRect:drawRect
				 stringForRect:as
				 messageTruncated:[aMessageData.truncated boolValue]
				 messageRange:CFRangeMake(locMessage, [aMessageData.textRepresentation length])
				 hintRange:CFRangeMake(locHint, (([self.messageData dataType] == kMessageString)?[defaultTextHint length]:[defaultDataHint length]))
				 frameSetter:framesetter];
			 
			 CFArrayAppendValue(self.textFrameContainer,frame);
			 CFRelease(frame);
		}

		CFAttributedStringEndEditing(as);
		self.displayString = as;
		CFRelease(as);
	}
	
	[self setNeedsDisplay];
}

// draw image data from ManagedObject model (LoggerMessage)
-(void)setImagedata:(NSData *)anImageData forRect:(CGRect)aRect
{
	// in case this cell is detached from tableview,
	if(self.superview == nil)
	{
		return;
	}
	
	UIImage *image = [[UIImage alloc] initWithData:anImageData];
	self.imageData = image;
	[image release],image = nil;
	
	//[self setNeedsDisplayInRect:aRect];
	[self setNeedsDisplay];
}

//------------------------------------------------------------------------------
#pragma mark - Draw Frame
//------------------------------------------------------------------------------
- (CGRect)timestampAndDeltaFrame:(CGRect)aBoundRect
{
	// Draw timestamp and time delta column
	CGRect r = CGRectMake(CGRectGetMinX(aBoundRect),
						  CGRectGetMinY(aBoundRect),
						  TIMESTAMP_COLUMN_WIDTH,
						  CGRectGetHeight(aBoundRect));
	return r;
}

- (CGRect)threadIDAndTagTextInRect:(CGRect)aBoundRect
{
	// Draw thread ID and tag
	CGRect r = CGRectMake(CGRectGetMinX(aBoundRect) + TIMESTAMP_COLUMN_WIDTH,
						  CGRectGetMinY(aBoundRect),
						  DEFAULT_THREAD_COLUMN_WIDTH,
						  CGRectGetHeight(aBoundRect));

	return r;
}

- (CGRect)fileLineFunctionTextInRect:(CGRect)aBoundRect
{
	return CGRectZero;
}

- (CGRect)messageTextInRect:(CGRect)aBoundRect
{
	CGRect r =	CGRectMake(CGRectGetMinX(aBoundRect) + (TIMESTAMP_COLUMN_WIDTH + DEFAULT_THREAD_COLUMN_WIDTH + MSG_CELL_LEFT_PADDING),
						   CGRectGetMinY(aBoundRect) + MSG_CELL_TOP_PADDING,
						   CGRectGetWidth(aBoundRect) - (TIMESTAMP_COLUMN_WIDTH + DEFAULT_THREAD_COLUMN_WIDTH + MSG_CELL_SIDE_PADDING),
						   CGRectGetHeight(aBoundRect) - MSG_CELL_TOP_BOTTOM_PADDING);
	return r;
}

//------------------------------------------------------------------------------
#pragma mark - CoreText Frame
//------------------------------------------------------------------------------
- (CTFrameRef)timestampAndDeltaTextInRect:(CGRect)aDrawRect
							stringForRect:(CFMutableAttributedStringRef)aString
						   timestampRange:(CFRange)aTimestampRange
							   deltaRange:(CFRange)aDeltaRange
							  frameSetter:(CTFramesetterRef)aFrameSetter
{
#ifdef DEBUG_CT_STR_RANGE
	NSAttributedString *s = (NSAttributedString *)aString;
	MTLog(@"\n\nts : %@",[[s attributedSubstringFromRange:NSMakeRange(aTimestampRange.location, aTimestampRange.length)] string]);
	MTLog(@"delta : %@",[[s attributedSubstringFromRange:NSMakeRange(aDeltaRange.location, aDeltaRange.length)] string]);
#endif
	CGRect tr = CGRectInset(aDrawRect, 2, 2);
	
	//TODO:: get color, underline, bold, hightlight etc
	CTFontRef f = [[LoggerTextStyleManager sharedStyleManager] defaultFont];
	CTParagraphStyleRef p = [[LoggerTextStyleManager sharedStyleManager] defaultParagraphStyle];
	
	//  Apply our font and line spacing attributes over the span
	CFAttributedStringSetAttribute(aString, aTimestampRange, kCTFontAttributeName, f);
	CFAttributedStringSetAttribute(aString, aTimestampRange, kCTParagraphStyleAttributeName, p);
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, tr);
	
	CTFrameRef frame = CTFramesetterCreateFrame(aFrameSetter, aTimestampRange, path, NULL);
	CGPathRelease(path);
	
	return frame;
}

- (CTFrameRef)threadIDAndTagTextInRect:(CGRect)aDrawRect
						 stringForRect:(CFMutableAttributedStringRef)aString
						   threadRange:(CFRange)aThreadRange
							  tagRange:(CFRange)aTagRange
							levelRange:(CFRange)aLevelRange
						   frameSetter:(CTFramesetterRef)aFrameSetter
{
#ifdef DEBUG_CT_STR_RANGE
	NSAttributedString *s = (NSAttributedString *)aString;
	MTLog(@"thread : %@",[[s attributedSubstringFromRange:NSMakeRange(aThreadRange.location, aThreadRange.length)] string]);
	MTLog(@"delta : %@",[[s attributedSubstringFromRange:NSMakeRange(aTagRange.location, aTagRange.length)] string]);
	MTLog(@"level : %@",[[s attributedSubstringFromRange:NSMakeRange(aLevelRange.location, aLevelRange.length)] string]);
#endif

	CTFontRef f = [[LoggerTextStyleManager sharedStyleManager] defaultTagAndLevelFont];
	CTParagraphStyleRef p = [[LoggerTextStyleManager sharedStyleManager] defaultTagAndLevelParagraphStyle];
	
	//@@TODO :: apply
	CFAttributedStringSetAttribute(aString, aThreadRange, kCTFontAttributeName, f);
	CFAttributedStringSetAttribute(aString, aThreadRange, kCTParagraphStyleAttributeName, p);

	CFAttributedStringSetAttribute(aString, aTagRange, kCTFontAttributeName, f);
	CFAttributedStringSetAttribute(aString, aTagRange, kCTParagraphStyleAttributeName, p);
	
	CFAttributedStringSetAttribute(aString, aLevelRange, kCTFontAttributeName, f);
	CFAttributedStringSetAttribute(aString, aLevelRange, kCTParagraphStyleAttributeName, p);
	
	CGMutablePathRef path = CGPathCreateMutable();

/*
	CGSize threadBounds = [LoggerTextStyleManager
	sizeForStringWithDefaultTagAndLevelFont:self.messageData.threadID
	constraint:aDrawRect.size];
*/
	
	CGPathAddRect(path, NULL, CGRectInset(aDrawRect, 3, 0));
	
	CTFrameRef frame = CTFramesetterCreateFrame(aFrameSetter, CFRangeMake(aThreadRange.location, aThreadRange.length + aTagRange.length + aLevelRange.length), path, NULL);
	
	return frame;
}

- (CTFrameRef)fileLineFunctionTextInRect:(CGRect)aDrawRect
						   stringForRect:(CFMutableAttributedStringRef)aString
							 stringRange:(CFRange)aStringRange
							 frameSetter:(CTFramesetterRef)aFrameSetter
{
#ifdef DEBUG_CT_STR_RANGE
	NSAttributedString *s = (NSAttributedString *)aString;
	MTLog(@"fileFunc : %@",[[s attributedSubstringFromRange:NSMakeRange(aStringRange.location, aStringRange.length)] string]);
#endif
	
	CTFontRef f = [[LoggerTextStyleManager sharedStyleManager] defaultTagAndLevelFont];
	CTParagraphStyleRef p = [[LoggerTextStyleManager sharedStyleManager] defaultTagAndLevelParagraphStyle];
	
	//@@TODO :: apply
	CFAttributedStringSetAttribute(aString, aStringRange, kCTFontAttributeName, f);
	CFAttributedStringSetAttribute(aString, aStringRange, kCTParagraphStyleAttributeName, p);
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, CGRectInset(aDrawRect, 3, 0));
	
	CTFrameRef frame = CTFramesetterCreateFrame(aFrameSetter, aStringRange, path, NULL);
	
	return frame;
}

- (CTFrameRef)messageTextInRect:(CGRect)aDrawRect
				  stringForRect:(CFMutableAttributedStringRef)aString
			   messageTruncated:(BOOL)truncated
				   messageRange:(CFRange)aMessageRange
					  hintRange:(CFRange)aHintRange
					frameSetter:(CTFramesetterRef)aFrameSetter
{
#ifdef DEBUG_CT_STR_RANGE
	NSAttributedString *s = (NSAttributedString *)aString;
	MTLog(@"message : %@",[[s attributedSubstringFromRange:NSMakeRange(aMessageRange.location, aMessageRange.length)] string]);

	if(truncated)
	{
		MTLog(@"hint : %@",[[s attributedSubstringFromRange:NSMakeRange(aHintRange.location, aHintRange.length)] string]);
	}
#endif
	
	
	CTFontRef f = [[LoggerTextStyleManager sharedStyleManager] defaultFont];
	CTParagraphStyleRef p = [[LoggerTextStyleManager sharedStyleManager] defaultParagraphStyle];

	CFAttributedStringSetAttribute(aString, aMessageRange, kCTFontAttributeName, f);
	CFAttributedStringSetAttribute(aString, aMessageRange, kCTParagraphStyleAttributeName, p);
	
	if(truncated){
		CFAttributedStringSetAttribute(aString, aHintRange, kCTFontAttributeName, f);
		CFAttributedStringSetAttribute(aString, aHintRange, kCTParagraphStyleAttributeName, p);
	}
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, aDrawRect);
	
	CFRange range;
	if(truncated){
		range = CFRangeMake(aMessageRange.location, aMessageRange.length + aHintRange.length);
	}else{
		range = aMessageRange;
	}

	CTFrameRef frame = CTFramesetterCreateFrame(aFrameSetter,range, path, NULL);
	CGPathRelease(path);;
	return frame;
}


//------------------------------------------------------------------------------
#pragma mark - Drawing Background
//------------------------------------------------------------------------------
- (void)drawTimestampAndDeltaInRect:(CGRect)aDrawRect
			   highlightedTextColor:(UIColor *)aHighlightedTextColor
{
	
}

- (void)drawThreadIDAndTagInRect:(CGRect)aDrawRect
			highlightedTextColor:(UIColor *)aHighlightedTextColor
{
	
#if 0
	
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

	CGSize threadBounds =
		[self.messageData.threadID
		 sizeWithFont:displayDefaultFont
		 forWidth:r.size.width
		 lineBreakMode:NSLineBreakByWordWrapping];

	r.size.height = threadBounds.height;
	
	[[UIColor grayColor] set];

	[self.messageData.threadID
	 drawInRect:CGRectInset(r, 3, 0)
	 withFont:displayDefaultFont
	 lineBreakMode:NSLineBreakByWordWrapping
	 alignment:NSTextAlignmentLeft];
#endif

#if 0
	
	// Draw tag and level, if provided
	NSString *tag = self.messageData.tag;
	int level = [self.messageData.level intValue];
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

#endif

#if 0
	CGSize threadBounds = [LoggerTextStyleManager
						   sizeForStringWithDefaultTagAndLevelFont:self.messageData.threadID
						   constraint:aDrawRect.size];
	
	
	CGRect r = aDrawRect;
	r.size.height = threadBounds.height;	
	
	// Draw tag and level, if provided
	NSString *tag = self.messageData.tag;
	int level = [self.messageData.level intValue];
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
#endif
}

- (void)drawFileLineFunctionInRect:(CGRect)aDrawRect
			  highlightedTextColor:(UIColor *)highlightedTextColor
{
// fill background
/*
	NSMutableDictionary *attrs = [self fileLineFunctionAttributes];
	if (highlightedTextColor == nil)
	{
		NSColor *fillColor = [attrs objectForKey:NSBackgroundColorAttributeName];
		if (fillColor != nil)
		{
			[fillColor set];
			NSRectFill(r);
		}
	}
*/
}

- (void)drawMessageInRect:(CGRect)aDrawRect
	 highlightedTextColor:(UIColor *)aHighlightedTextColor
{
	if([self.messageData dataType] == kMessageImage)
	{
		if(_imageData != nil)
		{
			//TODO:: drawing UIImage takes too much CPU time. find a way to fix it.
			CGRect r = CGRectInset(aDrawRect, 0, 1);
			CGSize srcSize = [_imageData size];
			CGFloat ratio = fmaxf(1.0f, fmaxf(srcSize.width / CGRectGetWidth(r), srcSize.height / CGRectGetHeight(r)));
			CGSize newSize = CGSizeMake(floorf(srcSize.width / ratio), floorf(srcSize.height / ratio));
			//CGRect imageRect = (CGRect){{CGRectGetMinX(r),CGRectGetMinY(r) + CGRectGetHeight(r)},newSize};
			CGRect imageRect = (CGRect){{CGRectGetMinX(r),CGRectGetMinY(r)},newSize};
			[self.imageData drawInRect:imageRect];
			
			self.imageData = nil;
		}
	}
}

//------------------------------------------------------------------------------
#pragma mark - drawRect()
//------------------------------------------------------------------------------
//TODO::try to come up with one big blob of texture
- (void)drawMessageView:(CGRect)cellFrame
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// turn antialiasing off
	CGContextSetShouldAntialias(context, false);

	//fill background with generic gray in value of 0.97f
	UIColor *backgroundColor = defaultBackgroundColor;
	[backgroundColor set];
	
	//@@TODO:: this single call represent 2% of CPU time. find a way to replace it.
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

	// top ceiling line
	CGContextMoveToPoint(context, CGRectGetMinX(cellFrame), floorf(CGRectGetMinY(cellFrame)));
	CGContextAddLineToPoint(context, CGRectGetMaxX(cellFrame), floorf(CGRectGetMinY(cellFrame)));
	
	// bottom floor line
	CGContextMoveToPoint(context, CGRectGetMinX(cellFrame), floorf(CGRectGetMaxY(cellFrame)));
	CGContextAddLineToPoint(context, CGRectGetMaxX(cellFrame), floorf(CGRectGetMaxY(cellFrame)));

	
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
	CGRect drawRect = [self timestampAndDeltaFrame:cellFrame];
	[self drawTimestampAndDeltaInRect:drawRect highlightedTextColor:nil];

#ifdef DEBUG_DRAW_AREA
	CGContextSetFillColorWithColor(context, [UIColor redColor].CGColor);
	CGContextFillRect(context, drawRect);
#endif
	
	// Draw thread ID and tag
	drawRect = [self threadIDAndTagTextInRect:cellFrame];
	[self drawThreadIDAndTagInRect:drawRect highlightedTextColor:nil];

#ifdef DEBUG_DRAW_AREA
	CGContextSetFillColorWithColor(context, [UIColor blueColor].CGColor);
	CGContextFillRect(context, drawRect);
#endif

	//@@TODO:: draw file && func area

	// Draw message
	drawRect = [self messageTextInRect:cellFrame];
	[self drawMessageInRect:drawRect highlightedTextColor:nil];

#ifdef DEBUG_DRAW_AREA
	CGContextSetFillColorWithColor(context, [UIColor yellowColor].CGColor);
	CGContextFillRect(context, drawRect);
#endif
	

#if 1
	CGContextSaveGState(context);
	// flip context vertically
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CGContextTranslateCTM(context, 0, self.bounds.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
	
	// draw all text frames
	CFIndex count = CFArrayGetCount(self.textFrameContainer);
	for(CFIndex i = 0; i < count; i++){
		CTFrameRef tf = (CTFrameRef)CFArrayGetValueAtIndex(self.textFrameContainer, i);
		CTFrameDraw(tf, context);
	}
	CGContextRestoreGState(context);
#endif
}

@end
