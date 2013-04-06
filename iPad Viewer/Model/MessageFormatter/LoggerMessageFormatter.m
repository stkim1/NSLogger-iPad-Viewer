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

#import "LoggerMessageFormatter.h"
#import "LoggerMessage.h"
#import "LoggerCommon.h"
#include <sys/time.h>

@implementation LoggerMessageFormatter
+(NSString *)formatTimestamp:(struct timeval * const)aTimestamp
{
	if(aTimestamp == NULL)
		return nil;

	time_t sec = aTimestamp->tv_sec;
	struct tm *t = localtime(&sec);
	NSString *timestampStr;

	if (aTimestamp->tv_usec == 0)
		timestampStr = [NSString stringWithFormat:@"%02d:%02d:%02d", t->tm_hour, t->tm_min, t->tm_sec];
	else
		timestampStr = [NSString stringWithFormat:@"%02d:%02d:%02d.%03d", t->tm_hour, t->tm_min, t->tm_sec, aTimestamp->tv_usec / 1000];
	
	return timestampStr;
}

+(NSString *)formatAndTruncateDisplayMessage:(LoggerMessage * const)aMessage truncated:(BOOL *)isTruncated
{
	NSString *displayMessage = nil;

	switch (aMessage.contentsType)
	{
		case kMessageString:{
			
			// in case the message text is empty, use the function name as message text
			// this is typically used to record a waypoint in the code flow
			NSString *message = nil;
			if (![aMessage.message length] && [aMessage.functionName length])
			{
				message = aMessage.functionName;
			}
			else
			{
				message = aMessage.message;
			}
			
			// very long messages can't be displayed entirely. No need to compute their full size,
			// it slows down the UI to no avail. Just cut the string to a reasonable size, and take
			// the calculations from here.
			if ([message length] > MSG_TRUNCATE_THREADHOLD_LENGTH)
			{
				displayMessage = [message substringToIndex:MSG_TRUNCATE_THREADHOLD_LENGTH];
				*isTruncated = TRUE;
			}
			else
			{
				displayMessage = message;
			}

			break;
		}
		case kMessageData:{
			NSData *message = aMessage.message;
			
			MTLog(@"contentsType %d",aMessage.contentsType);
			assert([message isKindOfClass:[NSData class]]);
			
			// convert NSData block to hex-ascii strings
			NSMutableString *strings = [[NSMutableString alloc] init];
			NSUInteger offset = 0, dataLen = [message length],line_count = 0;
			NSString *str;
			char buffer[1+6+16*3+1+16+1+1+1];
			buffer[0] = '\0';
			const unsigned char *q = [message bytes];
			if (dataLen == 1)
				[strings appendString:NSLocalizedString(@"Raw data, 1 byte:\n", nil)];
			else
				[strings appendFormat:NSLocalizedString(@"Raw data, %u bytes:\n", nil), dataLen];
			while (dataLen)
			{
				if (MAX_DATA_LINES <= line_count)
				{
					//we've reached the maximum length. bailout
					*isTruncated = TRUE;
					break;
				}

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
				[strings appendString:str];
				[str release];

				line_count++;
				dataLen -= i;
				offset += i;
				q += i;
			}
			displayMessage = [strings autorelease];
			break;
		}

		case kMessageImage:
		default:{
			break;
		}
	}

	return displayMessage;
}
@end
