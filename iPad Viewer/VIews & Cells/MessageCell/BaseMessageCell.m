/*
 *
 * BSD license follows (http://www.opensource.org/licenses/bsd-license.php)
 *
 * Copyright (c) 2012-2013 Sung-Taek, Kim <stkim1@colorfulglue.com> All Rights
 * Reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * Redistributions of  source code  must retain  the above  copyright notice,
 * this list of  conditions and the following  disclaimer. Redistributions in
 * binary  form must  reproduce  the  above copyright  notice,  this list  of
 * conditions and the following disclaimer  in the documentation and/or other
 * materials  provided with  the distribution.  Neither the  name of Sung-Tae
 * k Kim nor the names of its contributors may be used to endorse or promote
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

#import "BaseMessageCell.h"


NSString * const kMessageCellReuseID = @"messageCell";
UIFont *displayDefaultFont = nil;
UIFont *displayTagAndLevelFont = nil;
UIFont *displayMonospacedFont = nil;

CGColorRef defaultGrayColor = NULL;
CGColorRef defaultWhiteColor = NULL;

//#define USE_UIKIT_FOR_DRAWING
//#define DEBUG_CT_STR_RANGE
//#define DEBUG_CT_FRAME_RANGE
//#define DEBUG_DRAW_AREA

@interface LoggerMessageView : UIView
@end

@implementation LoggerMessageView
- (void)drawRect:(CGRect)aRect
{
	[(LoggerMessageCell *)[[self superview] superview] drawMessageView:aRect];
}
@end

@implementation BaseMessageCell
@synthesize hostTableView   = _hostTableView;
@synthesize messageData     = _messageData;

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
	
	CGColorSpaceRef csr = CGColorSpaceCreateDeviceRGB();
	if(defaultGrayColor == NULL){
		CGFloat fcomps[] = { 0.5f, 0.5f, 0.5f, 1.f };
		CGColorRef fc = CGColorCreate(csr, fcomps);
		defaultGrayColor = fc;
	}
    
	if(defaultWhiteColor == NULL)
	{
		CGFloat fcomps[] = { 1.f, 1.f, 1.f, 1.f };
		CGColorRef fc = CGColorCreate(csr, fcomps);
		defaultWhiteColor = fc;
	}

	CGColorSpaceRelease(csr);
    
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
    }
    return self;
}

- (instancetype)initWithIdentifier
{
	return
        [self
         initWithStyle:UITableViewCellStyleDefault
         reuseIdentifier:nil];
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
	self.messageData = nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

-(void)dealloc
{
    self.hostTableView = nil;
	self.messageData = nil;
    
    [super dealloc];
}

- (void)setupForIndexpath:(NSIndexPath *)anIndexPath
              messageData:(LoggerMessageData *)aMessageData
{
    self.messageData = aMessageData;
}


// this method actually draws message content. subclasses should draw their own
- (void)drawMessageView:(CGRect)cellFrame
{
    
}

- (void)drawMessageInRect:(CGRect)aDrawRect
	 highlightedTextColor:(UIColor *)aHighlightedTextColor
{
    
}

@end
