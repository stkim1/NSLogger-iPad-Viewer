//
//  LoggerMessageHeight.m
//  ipadnslogger
//
//  Created by Almighty Kim on 1/19/13.
//  Copyright (c) 2013 Colorful Glue. All rights reserved.
//

#import "LoggerMessageHeight.h"
#import "LoggerMessage.h"

static CGFloat	sMinimumHeightForCell = 0;
static CGFloat	sDefaultFileLineFunctionHeight = 0;
static UIFont	*sDisplayFont = nil;

@implementation LoggerMessageHeight

+ (void)initialize
{
	// load font resource and reuse it throughout app's lifecycle
	// since the font will never go out on main thread for drawing,
	// it is fine to do that
	if(sDisplayFont == nil)
	{
		sDisplayFont = [[UIFont systemFontOfSize:DEFAULT_FONT_SIZE] retain];
	}
}

+ (CGFloat)minimumHeightForCellOnWidth:(CGFloat)aWidth
{
	if(sMinimumHeightForCell == 0)
	{
		UIFont *defaultSizedFont = sDisplayFont;
		
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
		
		sMinimumHeightForCell = \
		fmaxf((r1.height + r2.height), (r3.height + r4.height)) + 4;
	}
	
	return sMinimumHeightForCell;
}

+ (CGFloat)heightForFileLineFunctionOnWidth:(CGFloat)aWidth
{
	if (sDefaultFileLineFunctionHeight == 0)
	{
		UIFont *defaultSizedFont = \
			[UIFont systemFontOfSize:DEFAULT_FONT_SIZE];

		CGSize r = [@"file:100 funcQyTg"
					sizeWithFont:defaultSizedFont
					forWidth:aWidth
					lineBreakMode:NSLineBreakByWordWrapping];

		sDefaultFileLineFunctionHeight = r.height + 6;
	}
	return sDefaultFileLineFunctionHeight;
}

+ (CGFloat)heightForMessage:(LoggerMessage *)aMessage onWidth:(CGFloat)aWidth
{
	CGFloat minimumHeight = \
		[LoggerMessageHeight
		 minimumHeightForCellOnWidth:aWidth];

	UIFont *defaultSizedFont = sDisplayFont;
	
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
