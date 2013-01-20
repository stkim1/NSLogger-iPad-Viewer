/*
 * LoggerMessage.m
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
#import <objc/runtime.h>
#import "LoggerMessage.h"
#import "LoggerCommon.h"
#import "LoggerConnection.h"
#import "NullStringCheck.h"

@implementation LoggerMessage
@synthesize tag, message, threadID;
@synthesize type, contentsType, level, timestamp;
@synthesize parts;
@synthesize image, imageSize;
@synthesize sequence;
@synthesize filename, functionName, lineNumber;
@dynamic messageText;
@dynamic messageType;
@synthesize textRepresentation = _textRepresentation;
@synthesize portraitHeight = _portraitHeight;
@synthesize landscapeHeight = _landscapeHeight;

- (id) init
{
	if ((self = [super init]) != nil)
	{
		_portraitHeight = _landscapeHeight = 0;
	}
	return self;
}

// -----------------------------------------------------------------------------
#pragma mark NSCopying
// -----------------------------------------------------------------------------
- (id)copyWithZone:(NSZone *)zone
{
	// Used only for displaying, we can afford not providing a real copy here
    return [self retain];
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

// -----------------------------------------------------------------------------
#pragma mark -
#pragma mark Special methods for use by predicates
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
#pragma mark - Message Height
//------------------------------------------------------------------------------
-(CGFloat)portraitHeight
{
	if(_portraitHeight == 0)
	{
		CGFloat height = 0;
		
		switch (self.type)
		{
			case LOGMSG_TYPE_LOG:
			case LOGMSG_TYPE_BLOCKSTART:
			case LOGMSG_TYPE_BLOCKEND:
				height = [LoggerMessageHeight
						  heightForMessage:self
						  onWidth:MSG_CELL_PORTRAIT_WIDTH];
				break;
			case LOGMSG_TYPE_CLIENTINFO:
			case LOGMSG_TYPE_DISCONNECT:
				height = [LoggerClientHeight
						  heightForMessage:self
						  onWidth:MSG_CELL_PORTRAIT_WIDTH];
				break;
			case LOGMSG_TYPE_MARK:
				height = [LoggerMarkerHeight
						  heightForMessage:self
						  onWidth:MSG_CELL_PORTRAIT_WIDTH];
				break;
		}
		_portraitHeight = height;
	}
	return _portraitHeight;
}


-(CGFloat)landscapeHeight
{
	if(_landscapeHeight == 0)
	{
		CGFloat height = 0;
		
		switch (self.type)
		{
			case LOGMSG_TYPE_LOG:
			case LOGMSG_TYPE_BLOCKSTART:
			case LOGMSG_TYPE_BLOCKEND:
				height = [LoggerMessageHeight
						  heightForMessage:self
						  onWidth:MSG_CELL_LANDSCAPE_WDITH];
				break;
			case LOGMSG_TYPE_CLIENTINFO:
			case LOGMSG_TYPE_DISCONNECT:
				height = [LoggerClientHeight
						  heightForMessage:self
						  onWidth:MSG_CELL_LANDSCAPE_WDITH];
				break;
			case LOGMSG_TYPE_MARK:
				height = [LoggerMarkerHeight
						  heightForMessage:self
						  onWidth:MSG_CELL_LANDSCAPE_WDITH];
				break;
		}
		_landscapeHeight = height;
	}
	return _landscapeHeight;
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
