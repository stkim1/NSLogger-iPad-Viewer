/*
 *
 * BSD license follows (http://www.opensource.org/licenses/bsd-license.php)
 *
 * Based on source code copyright (c) 2010-2014 Florent Pillet,
 * Copyright (c) 2012-2014 Sung-Taek, Kim <stkim1@colorfulglue.com> All Rights
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


#import "LoggerMarkerCell.h"

NSString * const kMarkerCellReuseID = @"markerCell";

@interface LoggerMarkerCell()
@property (nonatomic, strong) __attribute__((NSObject)) CTFrameRef textFrame;
@end

@implementation LoggerMarkerCell
-(id)initWithIdentifier
{
	return
		[self
		 initWithStyle:UITableViewCellStyleDefault
		 reuseIdentifier:kMarkerCellReuseID];
}

-(void)prepareForReuse
{
	[super prepareForReuse];
    self.textFrame = nil;
}

-(void)dealloc
{
    self.textFrame = nil;
    [super dealloc];
}

-(void)setupForIndexpath:(NSIndexPath *)anIndexPath
			 messageData:(LoggerMessageData *)aMessageData
{
	
    NSString *str = [aMessageData textRepresentation];
    
    
    CFMutableAttributedStringRef as = CFAttributedStringCreateMutable(kCFAllocatorDefault, [str length]);
    CFAttributedStringBeginEditing(as);

    // copy marker text
    CFAttributedStringReplaceString(as, CFRangeMake(0, 0), (CFStringRef)str);
    
    //TODO:: get color, underline, bold, hightlight etc
	CTFontRef f = [[LoggerTextStyleManager sharedStyleManager] defaultMonospacedFont];
	CTParagraphStyleRef p = [[LoggerTextStyleManager sharedStyleManager] defaultMonospacedStyle];
    CFRange rng = CFRangeMake(0,[str length]);

    // center alignment
    CTTextAlignment alignment = kCTTextAlignmentCenter;
    CTParagraphStyleSetting mfs[] = {
        {kCTParagraphStyleSpecifierAlignment,sizeof(CTTextAlignment),&alignment}
    };
    
    CTParagraphStyleRef style = CTParagraphStyleCreate(mfs, sizeof(mfs) / sizeof(mfs[0]));

    
	//  Apply our font and line spacing attributes over the span
	CFAttributedStringSetAttribute(as, rng, kCTFontAttributeName, f);
	CFAttributedStringSetAttribute(as, rng, kCTParagraphStyleAttributeName, p);
    CFAttributedStringSetAttribute(as, rng, kCTParagraphStyleAttributeName, style);
    
    
    // done editing the attributed string
    CFAttributedStringEndEditing(as);
    

    // Draw client info
	CGRect r = CGRectMake(MSG_CELL_LEFT_PADDING,MSG_CELL_TOP_PADDING,
						  MSG_CELL_PORTRAIT_WIDTH - MSG_CELL_LATERAL_PADDING,
						  [[aMessageData portraitHeight] floatValue] - MSG_CELL_VERTICAL_PADDING);
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(as);
    
    CGRect tr = CGRectInset(r, 2, 2);
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, tr);
	CTFrameRef frame = CTFramesetterCreateFrame(framesetter, rng, path, NULL);
    

    CFRelease(style);
    CGPathRelease(path);
    CFRelease(framesetter);
    CFRelease(as);
    
    // save text frame;
    self.textFrame = frame;
    
	[self setNeedsDisplay];
}

- (void)drawMessageView:(CGRect)cellFrame
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	BOOL highlighted = NO;
	
	UIColor *separatorColor =
		[UIColor
		 colorWithRed:(162.0f / 255.0f)
		 green:(174.0f / 255.0f)
		 blue:(10.0f / 255.0f)
		 alpha:1.f];
	
	if (!highlighted)
	{
		UIColor *backgroundColor =
			[UIColor
			 colorWithRed:1.f
			 green:1.f
			 blue:(197.0f / 255.0f)
			 alpha:1.f];
		
		[backgroundColor set];
		CGContextFillRect(context, cellFrame);
	}
	
	CGContextSetShouldAntialias(context, false);
	CGContextSetLineWidth(context, 1.0f);
	CGContextSetLineCap(context, kCGLineCapSquare);
	CGContextSetStrokeColorWithColor(context, separatorColor.CGColor);

	CGContextBeginPath(context);
	CGContextMoveToPoint(context, CGRectGetMinX(cellFrame), floorf(CGRectGetMinY(cellFrame)));
	CGContextAddLineToPoint(context, floorf(CGRectGetMaxX(cellFrame)), floorf(CGRectGetMinY(cellFrame)));
	CGContextMoveToPoint(context, CGRectGetMinX(cellFrame), floorf(CGRectGetMaxY(cellFrame)));
	CGContextAddLineToPoint(context, CGRectGetMaxX(cellFrame), floorf(CGRectGetMaxY(cellFrame)));
	CGContextStrokePath(context);
	CGContextSetShouldAntialias(context, true);
	
    
    // draw text
	CGContextSaveGState(context);
	// flip context vertically
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CGContextTranslateCTM(context, 0, self.bounds.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
		
    CTFrameDraw(self.textFrame, context);

	CGContextRestoreGState(context);
}

@end
