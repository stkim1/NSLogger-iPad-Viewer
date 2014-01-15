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
#import "LoggerUtils.h"

NSString * const kMessageCellReuseID = @"messageCell";
UIFont *displayDefaultFont = nil;
UIFont *displayTagAndLevelFont = nil;
UIFont *displayMonospacedFont = nil;

UIColor *defaultBackgroundColor = nil;
CGColorRef _defaultGrayColor = NULL;
CGColorRef _defaultWhiteColor = NULL;
CGColorRef _fileFuncBgColor = NULL;
CGColorRef _hintTextFgColor = NULL;

UIColor *defaultTagAndLevelColor = nil;

NSString *defaultTextHint = nil;
NSString *defaultDataHint = nil;

//#define USE_UIKIT_FOR_DRAWING
//#define DEBUG_CT_STR_RANGE
//#define DEBUG_CT_FRAME_RANGE
//#define DEBUG_DRAW_AREA

#define TEXT_LENGH_BETWEEN_LOCS(LOCATION_1,LOCATION_0) (abs(LOCATION_1 - LOCATION_0))
#define BORDER_LINE_WIDTH 1.f

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
		defaultBackgroundColor = [[UIColor whiteColor] retain];
/*
			[[UIColor
			 colorWithRed:DEAFULT_BACKGROUND_GRAY_VALUE
			 green:DEAFULT_BACKGROUND_GRAY_VALUE
			 blue:DEAFULT_BACKGROUND_GRAY_VALUE
			 alpha:1] retain];
*/
	}

	
	CGColorSpaceRef csr = CGColorSpaceCreateDeviceRGB();
	if(_defaultGrayColor == NULL){
		CGFloat fcomps[] = { 0.5f, 0.5f, 0.5f, 1.f };
		CGColorRef fc = CGColorCreate(csr, fcomps);
		_defaultGrayColor = fc;
	}

	if(_defaultWhiteColor == NULL)
	{
		CGFloat fcomps[] = { 1.f, 0.f, 0.f, 1.f };
		CGColorRef fc = CGColorCreate(csr, fcomps);
		_defaultWhiteColor = fc;
	}
	
	if(_fileFuncBgColor == NULL)
	{
		CGFloat comps[] = { (239.0f / 255.0f), (233.0f / 255.0f), (252.0f / 255.0f), 1.f };
		CGColorRef bc = CGColorCreate(csr, comps);
		_fileFuncBgColor = bc;
	}
	
	if(_hintTextFgColor == NULL)
	{
		CGFloat comps[] = { 0.3f, 0.3f, 0.3f, 1.f };
		CGColorRef fc = CGColorCreate(csr, comps);
		_hintTextFgColor = fc;
	}
	
	CGColorSpaceRelease(csr);

	if(defaultTagAndLevelColor == nil)
	{
		defaultTagAndLevelColor = [[UIColor colorWithRed:0.51f green:0.57f blue:0.79f alpha:1.0f] retain];
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
		float height = [[aMessageData portraitHeight] floatValue];
		float fflh = [aMessageData.portraitFileFuncHeight floatValue];
		
		// file func height
		if(!IS_NULL_STRING(aMessageData.fileFuncRepresentation))
		{
			height += fflh;
		}
		
		// add hint height if truncated
		if(truncated){
			//@@TODO:: find accruate height
			CGFloat hint = [[aMessageData portraitHintHeight] floatValue];
			height += hint + 100;
		}
		
		CGRect cellFrame = (CGRect){CGPointZero,{MSG_CELL_PORTRAIT_WIDTH,height}};
		
#ifdef DEBUG_DRAW_AREA
		MTLog(@"[s]cellFrame %@ %@",[[self.messageData sequence] stringValue],NSStringFromCGRect(cellFrame));
#endif
		
		// string range indexes
		int totalTextLength = 0;
		int locTimestamp	= 0;
		
		//@@TODO:: timedelta
		int locTimedelta	= locTimestamp + [aMessageData.timestampString length];
		int locThread		= locTimedelta;// + [aMessageData.timeDeltaString length];
		
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
	
		//timestamp & delta
		[self
		 timestampAndDeltaAttribute:as
		 timestampRange:CFRangeMake(locTimestamp, TEXT_LENGH_BETWEEN_LOCS(locTimedelta,locTimestamp))
		 deltaRange:CFRangeMake(locTimedelta, TEXT_LENGH_BETWEEN_LOCS(locThread,locTimedelta))
		 hightlighted:NO];

		// thread id
		[self
		 threadIDAttribute:as
		 threadRange:CFRangeMake(locThread, TEXT_LENGH_BETWEEN_LOCS(locTag,locThread))
		 hightlighted:NO];
		
		// tag attribute
		[self
		 tagAttribute:as
		 tagRange:CFRangeMake(locTag, TEXT_LENGH_BETWEEN_LOCS(locLevel,locTag))
		 hightlighted:NO];
		
		// level attribute
		[self
		 levelAttribute:as
		 levelRange:CFRangeMake(locLevel, TEXT_LENGH_BETWEEN_LOCS(locFileFunc,locLevel))
		 hightlighted:NO];
		
		// file name & function name
		if(!IS_NULL_STRING(aMessageData.fileFuncRepresentation))
		{
			[self
			 fileLineFunctionAttribute:as
			 stringRange:CFRangeMake(locFileFunc, TEXT_LENGH_BETWEEN_LOCS(locMessage,locFileFunc))
			 hightlighted:NO];
		}

		// message body & hint
		if([aMessageData dataType] != kMessageImage)
		{
			[self
			 messageAttribute:as
			 truncated:truncated
			 messageType:[aMessageData dataType]
			 messageRange:CFRangeMake(locMessage, TEXT_LENGH_BETWEEN_LOCS(locHint,locMessage))
			 hintRange:CFRangeMake(locHint, TEXT_LENGH_BETWEEN_LOCS(totalTextLength,locHint))
			 hightlighted:NO];
		}
		
		// done editing the attributed string
		CFAttributedStringEndEditing(as);
		
		
		
		
		
		
		CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(as);
		//timestamp and delta
		CGRect drawRect = [self timestampAndDeltaRect:cellFrame];
		CTFrameRef frame = \
			[self
			 timestampAndDeltaText:drawRect
			 stringForRect:as
			 stringRange:CFRangeMake(locTimestamp, TEXT_LENGH_BETWEEN_LOCS(locThread,locTimestamp))
			 frameSetter:framesetter];
			 
		CFArrayAppendValue(self.textFrameContainer,frame);
		CFRelease(frame);

		//thread id & tag
		drawRect = [self threadIDAndTagTextRect:cellFrame];
		frame = \
			[self
			 threadIDText:drawRect
			 stringForRect:as
			 stringRange:CFRangeMake(locThread, TEXT_LENGH_BETWEEN_LOCS(locTag,locThread))
			 frameSetter:framesetter];
				
		CGSize tsz = \
			[self
			 tagTextRect:drawRect
			 tagRange:CFRangeMake(locTag, TEXT_LENGH_BETWEEN_LOCS(locLevel,locTag))
			 levelRange:CFRangeMake(locLevel, TEXT_LENGH_BETWEEN_LOCS(locFileFunc,locLevel))
			 frameSetter:framesetter];

		//@@TODO:: formalize this area
		_tagDrawRect = (CGRect){drawRect.origin, tsz};
		
		
		CFArrayAppendValue(self.textFrameContainer,frame);
		CFRelease(frame);

		//file and function
		if(!IS_NULL_STRING(aMessageData.fileFuncRepresentation))
		{
			drawRect = [self fileLineFunctionTextRect:cellFrame lineHeight:fflh];
			frame = \
				[self
				 fileLineFunctionText:drawRect
				 stringForRect:as
				 stringRange:CFRangeMake(locFileFunc, [aMessageData.fileFuncRepresentation length])
				 frameSetter:framesetter];
			
			CFArrayAppendValue(self.textFrameContainer,frame);
			CFRelease(frame);
		}

		//message
		if([aMessageData dataType] != kMessageImage)
		{
			drawRect = [self messageTextRect:cellFrame fileFuncLineHeight:fflh];
			frame = \
				[self
				 messageText:drawRect
				 stringForRect:as
				 stringRange:CFRangeMake(locMessage, TEXT_LENGH_BETWEEN_LOCS(totalTextLength,locMessage))
				 frameSetter:framesetter];
			 
			 CFArrayAppendValue(self.textFrameContainer,frame);
			 CFRelease(frame);
		}

		// throw attributed string as well as frame setter.
		CFRelease(framesetter);
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
- (CGRect)timestampAndDeltaRect:(CGRect)aBoundRect
{
	// Draw timestamp and time delta column
	CGRect r = CGRectMake(CGRectGetMinX(aBoundRect),
						  CGRectGetMinY(aBoundRect),
						  TIMESTAMP_COLUMN_WIDTH,
						  CGRectGetHeight(aBoundRect));
	return r;
}

- (CGRect)threadIDAndTagTextRect:(CGRect)aBoundRect
{
	// Draw thread ID and tag
	CGRect r = CGRectMake(CGRectGetMinX(aBoundRect) + TIMESTAMP_COLUMN_WIDTH + MSG_CELL_LEFT_PADDING,
						  CGRectGetMinY(aBoundRect) + MSG_CELL_TOP_PADDING,
						  DEFAULT_THREAD_COLUMN_WIDTH - MSG_CELL_LATERAL_PADDING,
						  CGRectGetHeight(aBoundRect) - MSG_CELL_VERTICAL_PADDING);
	return r;
}

- (CGSize)tagTextRect:(CGRect)aConstraint
			 tagRange:(CFRange)aTagRange
		   levelRange:(CFRange)aLevelRange
		  frameSetter:(CTFramesetterRef)framesetter
{
	CFRange fitRange;
	CFRange textRange = CFRangeMake(aTagRange.location, aTagRange.length + aLevelRange.length);
	CGSize frameSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, textRange, NULL, aConstraint.size, &fitRange);

	return frameSize;
}

- (CGRect)fileLineFunctionTextRect:(CGRect)aBoundRect lineHeight:(CGFloat)aLineHeight
{
	//@@TODO : handle flipped coordinate system
	CGRect r =	CGRectMake(CGRectGetMinX(aBoundRect) + (TIMESTAMP_COLUMN_WIDTH + DEFAULT_THREAD_COLUMN_WIDTH + MSG_CELL_LEFT_PADDING),
						   CGRectGetMaxY(aBoundRect) - MSG_CELL_TOP_PADDING - aLineHeight,
						   CGRectGetWidth(aBoundRect) - (TIMESTAMP_COLUMN_WIDTH + DEFAULT_THREAD_COLUMN_WIDTH + MSG_CELL_LATERAL_PADDING),
						   aLineHeight);
	
	//MTLog(@"%s lineHeight %5.2f %@ %@",__PRETTY_FUNCTION__, aLineHeight, NSStringFromCGRect(r),self.messageData.fileFuncRepresentation);
	return r;
}

- (CGRect)messageTextRect:(CGRect)aBoundRect fileFuncLineHeight:(CGFloat)aLineHeight
{
	//@@TODO : handle flipped coordinate system
	CGRect r = CGRectMake(CGRectGetMinX(aBoundRect) + (TIMESTAMP_COLUMN_WIDTH + DEFAULT_THREAD_COLUMN_WIDTH + MSG_CELL_LEFT_PADDING),
						  CGRectGetMinY(aBoundRect) + MSG_CELL_TOP_PADDING,
						  CGRectGetWidth(aBoundRect) - (TIMESTAMP_COLUMN_WIDTH + DEFAULT_THREAD_COLUMN_WIDTH + MSG_CELL_LATERAL_PADDING),
						  CGRectGetHeight(aBoundRect) - MSG_CELL_VERTICAL_PADDING - aLineHeight);

	//MTLog(@"%s lineHeight %5.2f %@",__PRETTY_FUNCTION__, aLineHeight, NSStringFromCGRect(r));
	return r;
}

//------------------------------------------------------------------------------
#pragma mark - Text Attribute
//------------------------------------------------------------------------------
-(void)timestampAndDeltaAttribute:(CFMutableAttributedStringRef)aString
				   timestampRange:(CFRange)aTimestampRange
					   deltaRange:(CFRange)aDeltaRange
					 hightlighted:(BOOL)isHighlighted
{
#ifdef DEBUG_CT_STR_RANGE
	NSAttributedString *s = (NSAttributedString *)aString;
	MTLog(@"\n\nts : %@",[[s attributedSubstringFromRange:NSMakeRange(aTimestampRange.location, aTimestampRange.length)] string]);
	MTLog(@"delta : %@",[[s attributedSubstringFromRange:NSMakeRange(aDeltaRange.location, aDeltaRange.length)] string]);
#endif

	//TODO:: get color, underline, bold, hightlight etc
	CTFontRef f = [[LoggerTextStyleManager sharedStyleManager] defaultFont];
	CTParagraphStyleRef p = [[LoggerTextStyleManager sharedStyleManager] defaultParagraphStyle];
	
	//  Apply our font and line spacing attributes over the span
	CFAttributedStringSetAttribute(aString, aTimestampRange, kCTFontAttributeName, f);
	CFAttributedStringSetAttribute(aString, aTimestampRange, kCTParagraphStyleAttributeName, p);
}

- (void)threadIDAttribute:(CFMutableAttributedStringRef)aString
			  threadRange:(CFRange)aThreadRange
			 hightlighted:(BOOL)isHighlighted
{
#ifdef DEBUG_CT_STR_RANGE
	NSAttributedString *s = (NSAttributedString *)aString;
	MTLog(@"thread : %@",[[s attributedSubstringFromRange:NSMakeRange(aThreadRange.location, aThreadRange.length)] string]);
#endif
	
	CTFontRef f = [[LoggerTextStyleManager sharedStyleManager] defaultFont];
	CTParagraphStyleRef p = [[LoggerTextStyleManager sharedStyleManager] defaultParagraphStyle];
	
	CFAttributedStringSetAttribute(aString, aThreadRange, kCTFontAttributeName, f);
	CFAttributedStringSetAttribute(aString, aThreadRange, kCTParagraphStyleAttributeName, p);
	CFAttributedStringSetAttribute(aString, aThreadRange, kCTForegroundColorAttributeName, _defaultGrayColor);
}


- (void)tagAttribute:(CFMutableAttributedStringRef)aString
			tagRange:(CFRange)aTagRange
		hightlighted:(BOOL)isHighlighted
{
#ifdef DEBUG_CT_STR_RANGE
	NSAttributedString *s = (NSAttributedString *)aString;
	MTLog(@"tag : %@",[[s attributedSubstringFromRange:NSMakeRange(aTagRange.location, aTagRange.length)] string]);
	MTLog(@"level : %@",[[s attributedSubstringFromRange:NSMakeRange(aLevelRange.location, aLevelRange.length)] string]);
#endif

	CTFontRef tlf = [[LoggerTextStyleManager sharedStyleManager] defaultTagAndLevelFont];
	CTParagraphStyleRef tlp = [[LoggerTextStyleManager sharedStyleManager] defaultTagAndLevelStyle];
	
	CFAttributedStringSetAttribute(aString, aTagRange, kCTFontAttributeName, tlf);
	CFAttributedStringSetAttribute(aString, aTagRange, kCTParagraphStyleAttributeName, tlp);
	CFAttributedStringSetAttribute(aString, aTagRange, kCTForegroundColorAttributeName, _defaultWhiteColor);
}

- (void)levelAttribute:(CFMutableAttributedStringRef)aString
			levelRange:(CFRange)aLevelRange
		  hightlighted:(BOOL)isHighlighted
{
#ifdef DEBUG_CT_STR_RANGE
	NSAttributedString *s = (NSAttributedString *)aString;
	MTLog(@"tag : %@",[[s attributedSubstringFromRange:NSMakeRange(aTagRange.location, aTagRange.length)] string]);
	MTLog(@"level : %@",[[s attributedSubstringFromRange:NSMakeRange(aLevelRange.location, aLevelRange.length)] string]);
#endif
	
	CTFontRef tlf = [[LoggerTextStyleManager sharedStyleManager] defaultTagAndLevelFont];
	CTParagraphStyleRef tlp = [[LoggerTextStyleManager sharedStyleManager] defaultTagAndLevelStyle];
	
	CFAttributedStringSetAttribute(aString, aLevelRange, kCTFontAttributeName, tlf);
	CFAttributedStringSetAttribute(aString, aLevelRange, kCTParagraphStyleAttributeName, tlp);
	CFAttributedStringSetAttribute(aString, aLevelRange, kCTForegroundColorAttributeName, _defaultWhiteColor);
}



- (void)fileLineFunctionAttribute:(CFMutableAttributedStringRef)aString
					  stringRange:(CFRange)aStringRange
					 hightlighted:(BOOL)isHighlighted
{
#ifdef DEBUG_CT_STR_RANGE
	NSAttributedString *s = (NSAttributedString *)aString;
	MTLog(@"fileFunc : %@",[[s attributedSubstringFromRange:NSMakeRange(aStringRange.location, aStringRange.length)] string]);
#endif
	
	CTFontRef f = [[LoggerTextStyleManager sharedStyleManager] defaultFileAndFunctionFont];
	CTParagraphStyleRef p = [[LoggerTextStyleManager sharedStyleManager] defaultFileAndFunctionStyle];
	CFAttributedStringSetAttribute(aString, aStringRange, kCTFontAttributeName, f);
	CFAttributedStringSetAttribute(aString, aStringRange, kCTParagraphStyleAttributeName, p);
	CFAttributedStringSetAttribute(aString, aStringRange, kCTForegroundColorAttributeName, _defaultGrayColor);
	
	// not working *confirmed* :(
	//CFAttributedStringSetAttribute(aString, aStringRange, (CFStringRef)NSBackgroundColorAttributeName, _fileFuncBgColor);
}

- (void)messageAttribute:(CFMutableAttributedStringRef)aString
			   truncated:(BOOL)isTruncated
			 messageType:(LoggerMessageType)aMessageType
			messageRange:(CFRange)aMessageRange
			   hintRange:(CFRange)aHintRange
			hightlighted:(BOOL)isHighlighted
{
#ifdef DEBUG_CT_STR_RANGE
	NSAttributedString *s = (NSAttributedString *)aString;
	MTLog(@"message : %@",[[s attributedSubstringFromRange:NSMakeRange(aMessageRange.location, aMessageRange.length)] string]);
	
	if(isTruncated)
	{
		MTLog(@"hint : %@",[[s attributedSubstringFromRange:NSMakeRange(aHintRange.location, aHintRange.length)] string]);
	}
#endif
	
	if(aMessageType == kMessageString){
		
		CTFontRef f = [[LoggerTextStyleManager sharedStyleManager] defaultFont];
		CTParagraphStyleRef p = [[LoggerTextStyleManager sharedStyleManager] defaultParagraphStyle];
		
		CFAttributedStringSetAttribute(aString, aMessageRange, kCTFontAttributeName, f);
		CFAttributedStringSetAttribute(aString, aMessageRange, kCTParagraphStyleAttributeName, p);
				
	}else if(aMessageType == kMessageData){
		
		CTFontRef f = [[LoggerTextStyleManager sharedStyleManager] defaultMonospacedFont];
		CTParagraphStyleRef p = [[LoggerTextStyleManager sharedStyleManager] defaultMonospacedStyle];

		CFAttributedStringSetAttribute(aString, aMessageRange, kCTFontAttributeName, f);
		CFAttributedStringSetAttribute(aString, aMessageRange, kCTParagraphStyleAttributeName, p);
		
	}
	
	if(isTruncated){
		CTFontRef f = [[LoggerTextStyleManager sharedStyleManager] defaultHintFont];
		CTParagraphStyleRef p = [[LoggerTextStyleManager sharedStyleManager] defaultParagraphStyle];

		CFAttributedStringSetAttribute(aString, aHintRange, kCTFontAttributeName, f);
		CFAttributedStringSetAttribute(aString, aHintRange, kCTParagraphStyleAttributeName, p);
		CFAttributedStringSetAttribute(aString, aHintRange, kCTForegroundColorAttributeName, _hintTextFgColor);
	}
}


//------------------------------------------------------------------------------
#pragma mark - CoreText Frame
//------------------------------------------------------------------------------
- (CTFrameRef)timestampAndDeltaText:(CGRect)aDrawRect
					  stringForRect:(CFMutableAttributedStringRef)aString
						stringRange:(CFRange)aStringRange
						frameSetter:(CTFramesetterRef)aFrameSetter
{
#ifdef DEBUG_CT_FRAME_RANGE
	NSAttributedString *s = (NSAttributedString *)aString;
	MTLog(@"timestampAndDeltaText : %@",[[s attributedSubstringFromRange:NSMakeRange(aStringRange.location, aStringRange.length)] string]);
#endif
	
	CGRect tr = CGRectInset(aDrawRect, 2, 2);

	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, tr);
	CTFrameRef frame = CTFramesetterCreateFrame(aFrameSetter, aStringRange, path, NULL);
	CGPathRelease(path);
	
	return frame;
}

- (CTFrameRef)threadIDText:(CGRect)aDrawRect
			 stringForRect:(CFMutableAttributedStringRef)aString
			   stringRange:(CFRange)aStringRange
			   frameSetter:(CTFramesetterRef)aFrameSetter
{
#ifdef DEBUG_CT_FRAME_RANGE
	NSAttributedString *s = (NSAttributedString *)aString;
	MTLog(@"threadIDAndTagText : %@",[[s attributedSubstringFromRange:NSMakeRange(aStringRange.location, aStringRange.length)] string]);
#endif
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, aDrawRect);
	CTFrameRef frame = CTFramesetterCreateFrame(aFrameSetter,aStringRange, path, NULL);
	CGPathRelease(path);
	return frame;
}

- (CTFrameRef)tagText:(CGRect)aDrawRect
		stringForRect:(CFMutableAttributedStringRef)aString
		  stringRange:(CFRange)aStringRange
		  frameSetter:(CTFramesetterRef)aFrameSetter
{
#ifdef DEBUG_CT_FRAME_RANGE
	NSAttributedString *s = (NSAttributedString *)aString;
	MTLog(@"threadIDAndTagText : %@",[[s attributedSubstringFromRange:NSMakeRange(aStringRange.location, aStringRange.length)] string]);
#endif

	CGMutablePathRef path = CGPathCreateMutable();
/*
	CGSize threadBounds = [LoggerTextStyleManager
	sizeForStringWithDefaultTagAndLevelFont:self.messageData.threadID
	constraint:aDrawRect.size];
*/
	CGPathAddRect(path, NULL, aDrawRect);
	CTFrameRef frame = CTFramesetterCreateFrame(aFrameSetter,aStringRange, path, NULL);
	CGPathRelease(path);
	return frame;
}

- (CTFrameRef)LevelText:(CGRect)aDrawRect
		  stringForRect:(CFMutableAttributedStringRef)aString
			stringRange:(CFRange)aStringRange
			frameSetter:(CTFramesetterRef)aFrameSetter
{
#ifdef DEBUG_CT_FRAME_RANGE
	NSAttributedString *s = (NSAttributedString *)aString;
	MTLog(@"threadIDAndTagText : %@",[[s attributedSubstringFromRange:NSMakeRange(aStringRange.location, aStringRange.length)] string]);
#endif
	
	CGMutablePathRef path = CGPathCreateMutable();
	/*
	 CGSize threadBounds = [LoggerTextStyleManager
	 sizeForStringWithDefaultTagAndLevelFont:self.messageData.threadID
	 constraint:aDrawRect.size];
	 */
	CGPathAddRect(path, NULL, aDrawRect);
	CTFrameRef frame = CTFramesetterCreateFrame(aFrameSetter,aStringRange, path, NULL);
	CGPathRelease(path);
	return frame;
}


- (CTFrameRef)fileLineFunctionText:(CGRect)aDrawRect
					 stringForRect:(CFMutableAttributedStringRef)aString
					   stringRange:(CFRange)aStringRange
					   frameSetter:(CTFramesetterRef)aFrameSetter
{
#ifdef DEBUG_CT_FRAME_RANGE
	NSAttributedString *s = (NSAttributedString *)aString;
	MTLog(@"fileLineFunctionText : %@",[[s attributedSubstringFromRange:NSMakeRange(aStringRange.location, aStringRange.length)] string]);
#endif
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, aDrawRect);
	CTFrameRef frame = CTFramesetterCreateFrame(aFrameSetter, aStringRange, path, NULL);
	CGPathRelease(path);
	return frame;
}

- (CTFrameRef)messageText:(CGRect)aDrawRect
			stringForRect:(CFMutableAttributedStringRef)aString
			  stringRange:(CFRange)aStringRange
			  frameSetter:(CTFramesetterRef)aFrameSetter
{
#ifdef DEBUG_CT_FRAME_RANGE
	NSAttributedString *s = (NSAttributedString *)aString;
	MTLog(@"messageText : %@\n\n",[[s attributedSubstringFromRange:NSMakeRange(aStringRange.location, aStringRange.length)] string]);
#endif
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, aDrawRect);
	CTFrameRef frame = CTFramesetterCreateFrame(aFrameSetter,aStringRange, path, NULL);
	CGPathRelease(path);
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
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	UIColor *black = GRAYCOLOR(0.25f);
	CGContextSaveGState(context);
	CGContextSetFillColorWithColor(context, [black CGColor]);
	CGContextClipToRect(context,_tagDrawRect);
	MakeRoundedPath(context, _tagDrawRect, 3.0f);
	CGContextFillPath(context);
	CGContextRestoreGState(context);

	
	
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
	CGContextSetLineWidth(context, BORDER_LINE_WIDTH);
	CGContextSetLineCap(context, kCGLineCapSquare);
	UIColor *cellSeparatorColor = GRAYCOLOR(0.8f);
#if 0
	if (highlighted)
		cellSeparatorColor = CGColorCreateGenericGray(1.0f, BORDER_LINE_WIDTH);
	else
		cellSeparatorColor = CGColorCreateGenericGray(0.80f, BORDER_LINE_WIDTH);
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
	CGRect drawRect = [self timestampAndDeltaRect:cellFrame];
	[self drawTimestampAndDeltaInRect:drawRect highlightedTextColor:nil];

#ifdef DEBUG_DRAW_AREA
	MTLog(@"[d]cellFrame %@ %@\n\n",[[self.messageData sequence] stringValue],NSStringFromCGRect(cellFrame));
	CGContextSetFillColorWithColor(context, [UIColor redColor].CGColor);
	CGContextFillRect(context, drawRect);
#endif
	
	// Draw thread ID and tag
	drawRect = [self threadIDAndTagTextRect:cellFrame];
	[self drawThreadIDAndTagInRect:drawRect highlightedTextColor:nil];

//#ifdef DEBUG_DRAW_AREA
#if 1
	CGContextSetFillColorWithColor(context, [UIColor yellowColor].CGColor);
	CGContextFillRect(context, drawRect);
#endif

	//@@TODO:: draw file && func area

	// Draw message

	float fflh = [[self.messageData portraitFileFuncHeight] floatValue];
	drawRect = [self messageTextRect:cellFrame fileFuncLineHeight:fflh];
	[self drawMessageInRect:drawRect highlightedTextColor:nil];

#ifdef DEBUG_DRAW_AREA
	CGContextSetFillColorWithColor(context, [UIColor yellowColor].CGColor);
	CGContextFillRect(context, drawRect);
#endif


	CGContextSaveGState(context);
	// flip context vertically
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CGContextTranslateCTM(context, 0, self.bounds.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
	
#if DEBUG_DRAW_AREA ||  1
	
	if(!IS_NULL_STRING(self.messageData.fileFuncRepresentation))
	{
		CGRect d =
			(CGRect){{CGRectGetMinX(cellFrame) + (TIMESTAMP_COLUMN_WIDTH + DEFAULT_THREAD_COLUMN_WIDTH + BORDER_LINE_WIDTH),CGRectGetMaxY(cellFrame)  - fflh},
					{CGRectGetWidth(cellFrame) - (TIMESTAMP_COLUMN_WIDTH + DEFAULT_THREAD_COLUMN_WIDTH + BORDER_LINE_WIDTH),fflh}};

		CGContextSetFillColorWithColor(context, _fileFuncBgColor);
		CGContextFillRect(context,d);
	}

	if(NO)
	{
		CGRect d = [self messageTextRect:cellFrame fileFuncLineHeight:fflh];
		CGPathRef path = CGPathCreateWithRect(d,NULL);
		CGContextSetFillColorWithColor(context, [UIColor cyanColor].CGColor);
		CGContextFillRect(context, CGPathGetBoundingBox(path));
		CGPathRelease(path);
	}
#endif
	
	// draw all text frames
	CFIndex count = CFArrayGetCount(self.textFrameContainer);
	for(CFIndex i = 0; i < count; i++){
		CTFrameRef tf = (CTFrameRef)CFArrayGetValueAtIndex(self.textFrameContainer, i);
		CTFrameDraw(tf, context);
	}
	CGContextRestoreGState(context);
}

@end
