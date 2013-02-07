/*
 * LoggerMessageHeight.m
 *
 * BSD license follows (http://www.opensource.org/licenses/bsd-license.php)
 *
 * Copyright (c) 2010-2011 Florent Pillet <fpillet@gmail.com> All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * Redistributions of  source code  must retain  the above  copyright notice,
 * this list of  conditions and the following  disclaimer. Redistributions in
 * binary  form must  reproduce  the  above copyright  notice,  this list  of
 * conditions and the following disclaimer  in the documentation and/or other
 * materials  provided with  the distribution.  Neither the  name of  Florent
 * Pillet nor the names of its contributors may be used to endorse or promote
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

#import "LoggerMessageHeight.h"
#import "LoggerMessage.h"

static CGFloat	_minimumHeightForCell = 0;
static CGFloat	_defaultFileLineFunctionHeight = 0;
static UIFont	*_measureDefaultFont = nil;

@implementation LoggerMessageHeight

+ (void)initialize
{
	// load font resource and reuse it throughout app's lifecycle
	// since the font will never go out on main thread for drawing,
	// it is fine to do that
	if(_measureDefaultFont == nil)
	{
		_measureDefaultFont = [[UIFont fontWithName:kDefaultFontName size:DEFAULT_FONT_SIZE] retain];
	}
}

+ (CGFloat)minimumHeightForCellOnWidth:(CGFloat)aWidth
{
	if(_minimumHeightForCell == 0)
	{
		UIFont *defaultSizedFont = _measureDefaultFont;
		
		CGSize r1 = [@"10:10:10.256"
					 sizeWithFont:defaultSizedFont
					 forWidth:aWidth
					 lineBreakMode:NSLineBreakByWordWrapping];
		
		CGSize r2 = [@"+999ms"
					 sizeWithFont:defaultSizedFont
					 forWidth:aWidth
					 lineBreakMode:NSLineBreakByWordWrapping];
		
		CGSize r3 = [@"Main Thread"
					 sizeWithFont:defaultSizedFont
					 forWidth:aWidth
					 lineBreakMode:NSLineBreakByWordWrapping];
		
		CGSize r4 = [@"qWTy"
					 sizeWithFont:defaultSizedFont
					 forWidth:aWidth
					 lineBreakMode:NSLineBreakByWordWrapping];
		
		_minimumHeightForCell = \
		fmaxf((r1.height + r2.height), (r3.height + r4.height)) + 4;
	}
	
	return _minimumHeightForCell;
}

+ (CGFloat)heightForFileLineFunctionOnWidth:(CGFloat)aWidth
{
	if (_defaultFileLineFunctionHeight == 0)
	{
		UIFont *defaultSizedFont = \
			[UIFont systemFontOfSize:DEFAULT_FONT_SIZE];

		CGSize r = [@"file:100 funcQyTg"
					sizeWithFont:defaultSizedFont
					forWidth:aWidth
					lineBreakMode:NSLineBreakByWordWrapping];

		_defaultFileLineFunctionHeight = r.height + 6;
	}
	return _defaultFileLineFunctionHeight;
}

+ (CGFloat)heightForMessage:(LoggerMessage *)aMessage onWidth:(CGFloat)aWidth
{
	CGFloat minimumHeight = \
		[LoggerMessageHeight
		 minimumHeightForCellOnWidth:aWidth];

	UIFont *defaultSizedFont = _measureDefaultFont;
	
	CGSize sz = CGSizeMake(aWidth, minimumHeight);

	sz.width -= TIMESTAMP_COLUMN_WIDTH + DEFAULT_THREAD_COLUMN_WIDTH + 8;
	sz.height -= 4;
	
	switch (aMessage.contentsType)
	{
		case kMessageString: {
			// restrict message length for very long contents
			NSString *s = aMessage.message;
			if ([s length] > 2048)
				s = [s substringToIndex:2048];
			
			CGSize lr = [s
						 sizeWithFont:defaultSizedFont
						 forWidth:aWidth
						 lineBreakMode:NSLineBreakByWordWrapping];
			sz.height = fminf(lr.height, sz.height);
			break;
		}

		case kMessageData: {
			NSUInteger numBytes = [(NSData *)aMessage.message length];
			int nLines = (numBytes >> 4) + ((numBytes & 15) ? 1 : 0) + 1;
			if (nLines > MAX_DATA_LINES)
				nLines = MAX_DATA_LINES + 1;
			CGSize lr = [@"000:"
						 sizeWithFont:defaultSizedFont
						 forWidth:aWidth
						 lineBreakMode:NSLineBreakByWordWrapping];
			sz.height = lr.height * nLines;
			break;
		}

		case kMessageImage: {
			// approximate, compute ratio then refine height
			CGSize imgSize = aMessage.imageSize;
			CGFloat ratio = fmaxf(1.0f, fmaxf(imgSize.width / sz.width, imgSize.height / (sz.height / 2.0f)));
			sz.height = ceilf(imgSize.height / ratio);
			break;
		}
		default:
			break;
	}
	
	// return calculated cell height
	return fmaxf(sz.height + 6, minimumHeight);
}

+ (CGFloat)heightForFileLineFunctionOfMessage:(LoggerMessage *)aMessage onWidth:(CGFloat)aWidth
{
	// If there is file / line / function information, add its height
	if ([aMessage.filename length] || [aMessage.functionName length])
		return [LoggerMessageHeight heightForFileLineFunctionOnWidth:aWidth];

	return 0.f;
}

@end
