/*
 *
 * Modified BSD license.
 *
 * Based on source code copyright (c) 2010-2012 Florent Pillet,
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

#import <objc/runtime.h>
#import "LoggerMessage.h"
#import "LoggerCommon.h"
#import "LoggerConnection.h"
#import "NullStringCheck.h"

/*
#import "LoggerMessageHeight.h"
#import "LoggerClientHeight.h"
#import "LoggerMarkerHeight.h"
*/

#import "LoggerMessageFormatter.h"

#import "LoggerMessageSize.h"
#import "LoggerClientSize.h"
#import "LoggerMarkerSize.h"

@implementation LoggerMessage
@synthesize tag, message, threadID;
@synthesize type, contentsType, level, timestamp;
@synthesize parts;
@synthesize image, imageSize;
@synthesize sequence;
@synthesize timestampString = _timestampString;
@synthesize filename, functionName, lineNumber;
@synthesize textRepresentation = _textRepresentation;
@synthesize truncated = _truncated;


@dynamic messageText;
@dynamic messageType;

@dynamic portraitHeight;
@dynamic portraitMessageSize;
@dynamic portraitHintSize;

@dynamic landscapeHeight;
@dynamic landscapeMessageSize;
@dynamic landscapeHintSize;

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		_portraitMessageSize = _landscapeMessageSize = CGSizeZero;
		_portraitHintSize = _landscapeHintSize = CGSizeZero;
		_truncated = NO;
	}
	return self;
}

- (void)dealloc
{
	[tag release];
	[filename release];
	[functionName release];
	[parts release];
	[message release];
	[image release];
	[threadID release];
	[_timestampString release];
	[_textRepresentation release];
	[super dealloc];
}

- (UIImage *)image
{
	if (contentsType != kMessageImage)
		return nil;
	if (image == nil)
		image = [[UIImage alloc] initWithData:message];
	return image;
}

- (CGSize)imageSize
{
	if (imageSize.width == 0 || imageSize.height == 0)
		imageSize = self.image.size;
	return imageSize;
}

#if 0
- (NSString *)textRepresentation
{
	if(!IS_NULL_STRING(_textRepresentation))
		return _textRepresentation;
	
	// Prepare a text representation of the message, suitable for export of text field display
	time_t sec = timestamp.tv_sec;
	struct tm *t = localtime(&sec);

	if (contentsType == kMessageString)
	{
		if (type == LOGMSG_TYPE_MARK)
		{
			_textRepresentation = [[NSString stringWithFormat:@"%@\n", message] retain];
			return _textRepresentation;
		}

		/* commmon case */
		
		// if message is empty, use the function name (typical case of using a log to record
		// a "waypoint" in the code flow)
		NSString *s = message;
		if (![s length] && [functionName length])
			s = functionName;

		_textRepresentation = \
			[[NSString
			  stringWithFormat:@"[%-8u] %02d:%02d:%02d.%03d | %@ | %@ | %@\n"
			  ,sequence
			  ,t->tm_hour
			  ,t->tm_min
			  ,t->tm_sec
			  ,timestamp.tv_usec / 1000
			  ,(tag == NULL) ? @"-" : tag
			  ,threadID
#warning shouldn't this be functionName?
			  //,message] retain];
			  ,s] retain];

		return _textRepresentation;
	}

	NSString *header = [NSString
						stringWithFormat:@"[%-8u] %02d:%02d:%02d.%03d | %@ | %@ | "
						,sequence
						,t->tm_hour
						,t->tm_min
						,t->tm_sec
						,timestamp.tv_usec / 1000
						,(tag == NULL) ? @"-" : tag
						,threadID];

	if (contentsType == kMessageImage){
		_textRepresentation = \
			[[NSString
			  stringWithFormat:@"%@IMAGE size=%dx%d px\n"
			  ,header
			  ,(int)self.imageSize.width
			  ,(int)self.imageSize.height]
			 retain];

		return _textRepresentation;
	}

	assert([message isKindOfClass:[NSData class]]);
	NSMutableString *s = [[NSMutableString alloc] init];
	[s appendString:header];
	NSUInteger offset = 0, dataLen = [message length];
	NSString *str;
	char buffer[1+6+16*3+1+16+1+1+1];
	buffer[0] = '\0';
	const unsigned char *q = [message bytes];
	if (dataLen == 1)
		[s appendString:NSLocalizedString(@"Raw data, 1 byte:\n", @"")];
	else
		[s appendFormat:NSLocalizedString(@"Raw data, %u bytes:\n", @""), dataLen];
	while (dataLen)
	{
		int i, b = sprintf(buffer," %04x: ", offset);
		for (i=0; i < 16 && i < dataLen; i++)
			sprintf(&buffer[b+3*i], "%02x ", (int)q[i]);
		for (int j=i; j < 16; j++)
			strcat(buffer, "   ");
		
		b = strlen(buffer);
		buffer[b++] = '\'';
		for (i=0; i < 16 && i < dataLen; i++)
		{
			if (q[i] >= 32 && q[i] < 128)
				buffer[b++] = q[i];
			else
				buffer[b++] = ' ';
		}
		for (int j=i; j < 16; j++)
			buffer[b++] = ' ';
		buffer[b++] = '\'';
		buffer[b++] = '\n';
		buffer[b] = 0;
		
		str = [[NSString alloc] initWithBytes:buffer length:strlen(buffer) encoding:NSISOLatin1StringEncoding];
		[s appendString:str];
		[str release];
		
		dataLen -= i;
		offset += i;
		q += i;
	}

	_textRepresentation = s;
	return _textRepresentation;
}
#endif



#pragma mark - 
- (void)formatMessage
{
	NSString *formattedMessage = nil;
	
	switch (type) {
		case LOGMSG_TYPE_CLIENTINFO:{
			
			formattedMessage = \
				[LoggerMessageFormatter formatClientInfoMessage:self];
			[formattedMessage retain];
			// set message body
			[_textRepresentation release],_textRepresentation = nil;
			_textRepresentation = formattedMessage;

			threadID = nil;
			_truncated = NO;

			CGSize size __attribute__((unused)) = [self portraitMessageSize];
			size = [self landscapeMessageSize];


			break;
		}
		default:{
			// message format
			NSString *formattedMessage =
				[LoggerMessageFormatter
				 formatAndTruncateDisplayMessage:self
				 truncated:&_truncated];
			[formattedMessage retain];

			// set message body
			[_textRepresentation release],_textRepresentation = nil;
			_textRepresentation = formattedMessage;
			
			// in case image message, preload image
			if(contentsType == kMessageImage){
				UIImage *formattedImage __attribute__((unused)) = [self image];
			}

			CGSize size __attribute__((unused)) = [self portraitMessageSize];
			size = [self landscapeMessageSize];

			if(_truncated)
			{
				size = [self portraitHintSize];
				size = [self landscapeHintSize];
			}
			
			break;
		}
	}
	
	// set timestamp string
	NSString *ts = [LoggerMessageFormatter formatTimestamp:&timestamp];
	[ts retain];
	[_timestampString release],_timestampString = nil;
	_timestampString = ts;
}


// -----------------------------------------------------------------------------
#pragma mark -
// -----------------------------------------------------------------------------
- (NSString *)messageText
{
	if (contentsType == kMessageString)
		return message;
	return nil;
}

- (NSString *)messageType
{
	if (contentsType == kMessageString)
		return @"text";
	if (contentsType == kMessageData)
		return @"data";
	return @"img";
}



//------------------------------------------------------------------------------
#pragma mark - Message size
//------------------------------------------------------------------------------
-(CGFloat)portraitHeight
{
	CGFloat height = _portraitMessageSize.height;
	
	if(_truncated)
	{
		height += _portraitHintSize.height;
	}
	
	height += MSG_CELL_TOP_BOTTOM_PADDING;
	return height;
}

-(CGSize)portraitMessageSize
{
	if(CGSizeEqualToSize(_portraitMessageSize, CGSizeZero))
	{
		CGSize size;
		CGFloat maxWidth = \
			MSG_CELL_PORTRAIT_WIDTH-(TIMESTAMP_COLUMN_WIDTH + DEFAULT_THREAD_COLUMN_WIDTH + MSG_CELL_SIDE_PADDING);
		
		CGFloat maxHeight = MSG_CELL_PORTRAIT_MAX_HEIGHT;
		if(_truncated)
		{
			maxHeight -= MSG_CELL_TOP_PADDING;
		}
		else
		{
			maxHeight -= MSG_CELL_TOP_BOTTOM_PADDING;
		}
		
		switch (self.type)
		{
			case LOGMSG_TYPE_LOG:
			case LOGMSG_TYPE_BLOCKSTART:
			case LOGMSG_TYPE_BLOCKEND:{
				size = [LoggerMessageSize
						sizeOfMessage:self
						maxWidth:maxWidth
						maxHeight:maxHeight];
				break;
			}
			case LOGMSG_TYPE_CLIENTINFO:
			case LOGMSG_TYPE_DISCONNECT:{
				size = [LoggerClientSize
						sizeOfMessage:self
						maxWidth:maxWidth
						maxHeight:maxHeight];
				break;
			}
			case LOGMSG_TYPE_MARK:{
				size = [LoggerMarkerSize
						sizeOfMessage:self
						maxWidth:maxWidth
						maxHeight:maxHeight];
				break;
			}
		}

		_portraitMessageSize = size;
	}
	
	return _portraitMessageSize;
}

-(CGSize)portraitHintSize
{
	if(CGSizeEqualToSize(_portraitHintSize, CGSizeZero))
	{
		
		CGSize size;
		CGFloat maxWidth = \
			MSG_CELL_PORTRAIT_WIDTH-(TIMESTAMP_COLUMN_WIDTH + DEFAULT_THREAD_COLUMN_WIDTH + MSG_CELL_SIDE_PADDING);
		CGFloat maxHeight = MSG_CELL_PORTRAIT_MAX_HEIGHT - MSG_CELL_TOP_PADDING;
		
		switch (self.type)
		{
			case LOGMSG_TYPE_LOG:
			case LOGMSG_TYPE_BLOCKSTART:
			case LOGMSG_TYPE_BLOCKEND:{
				size = [LoggerMessageSize
						sizeOfHint:self
						maxWidth:maxWidth
						maxHeight:maxHeight];
				break;
			}
			default:
				break;
		}
		
		_portraitHintSize = size;
	}
	
	return _portraitHintSize;
}

-(CGFloat)landscapeHeight
{
	CGFloat height = _landscapeMessageSize.height;
	
	if(_truncated)
	{
		height += _landscapeHintSize.height;
	}
	
	height += MSG_CELL_TOP_BOTTOM_PADDING;
	return height;
}

-(CGSize)landscapeMessageSize
{
	if(CGSizeEqualToSize(_landscapeMessageSize, CGSizeZero))
	{
		CGSize size;
		CGFloat maxWidth = \
			MSG_CELL_LANDSCAPE_WDITH-(TIMESTAMP_COLUMN_WIDTH + DEFAULT_THREAD_COLUMN_WIDTH + MSG_CELL_SIDE_PADDING);
		
		CGFloat maxHeight = MSG_CELL_LANDSCALE_MAX_HEIGHT;

		if(_truncated)
		{
			maxHeight -= MSG_CELL_TOP_PADDING;
		}
		else
		{
			maxHeight -= MSG_CELL_TOP_BOTTOM_PADDING;
		}
			

		switch (self.type)
		{
			case LOGMSG_TYPE_LOG:
			case LOGMSG_TYPE_BLOCKSTART:
			case LOGMSG_TYPE_BLOCKEND:{
				size = [LoggerMessageSize
						sizeOfMessage:self
						maxWidth:maxWidth
						maxHeight:maxHeight];
				break;
			}
			case LOGMSG_TYPE_CLIENTINFO:
			case LOGMSG_TYPE_DISCONNECT:{
				size = [LoggerClientSize
						sizeOfMessage:self
						maxWidth:maxWidth
						maxHeight:maxHeight];
				break;
			}
			case LOGMSG_TYPE_MARK:{
				size = [LoggerMarkerSize
						sizeOfMessage:self
						maxWidth:maxWidth
						maxHeight:maxHeight];
				break;
			}
		}

		_landscapeMessageSize = size;
	}

	return _landscapeMessageSize;
}

-(CGSize)landscapeHintSize
{
	if (CGSizeEqualToSize(_landscapeHintSize, CGSizeZero))
	{
		CGSize size;
		CGFloat maxWidth = \
			MSG_CELL_LANDSCAPE_WDITH-(TIMESTAMP_COLUMN_WIDTH + DEFAULT_THREAD_COLUMN_WIDTH + MSG_CELL_SIDE_PADDING);
		CGFloat maxHeight = MSG_CELL_LANDSCALE_MAX_HEIGHT - MSG_CELL_TOP_PADDING;
		
		switch (self.type)
		{
			case LOGMSG_TYPE_LOG:
			case LOGMSG_TYPE_BLOCKSTART:
			case LOGMSG_TYPE_BLOCKEND:{
				size = [LoggerMessageSize
						sizeOfHint:self
						maxWidth:maxWidth
						maxHeight:maxHeight];
				break;
			}
			default:
				break;
		}

		_landscapeHintSize = size;

	}
	
	return _landscapeHintSize;
}


// -----------------------------------------------------------------------------
#pragma mark - Other
// -----------------------------------------------------------------------------
- (void)computeTimeDelta:(struct timeval *)td since:(LoggerMessage *)previousMessage
{
	assert(previousMessage != NULL);
	double t1 = (double)timestamp.tv_sec + ((double)timestamp.tv_usec) / 1000000.0;
	double t2 = (double)previousMessage->timestamp.tv_sec + ((double)previousMessage->timestamp.tv_usec) / 1000000.0;
	double t = t1 - t2;
	td->tv_sec = (__darwin_time_t)t;
	td->tv_usec = (__darwin_suseconds_t)((t - (double)td->tv_sec) * 1000000.0);
}

#ifdef DEBUG
-(NSString *)description
{
	NSString *typeString = ((type == LOGMSG_TYPE_LOG) ? @"Log" :
							(type == LOGMSG_TYPE_CLIENTINFO) ? @"ClientInfo" :
							(type == LOGMSG_TYPE_DISCONNECT) ? @"Disconnect" :
							(type == LOGMSG_TYPE_BLOCKSTART) ? @"BlockStart" :
							(type == LOGMSG_TYPE_BLOCKEND) ? @"BlockEnd" :
							(type == LOGMSG_TYPE_MARK) ? @"Mark" :
							@"Unknown");
	NSString *desc;
	if (contentsType == kMessageData)
		desc = [NSString stringWithFormat:@"{data %u bytes}", [message length]];
	else if (contentsType == kMessageImage)
		desc = [NSString stringWithFormat:@"{image w=%d h=%d}", (NSInteger)[self imageSize].width, (NSInteger)[self imageSize].height];
	else
		desc = (NSString *)message;
	
	return [NSString stringWithFormat:@"<%@ %p seq=%d type=%@ thread=%@ tag=%@ level=%d message=%@>",
			[self class], self, sequence, typeString, threadID, tag, (int)level, desc];
}
#endif

@end
