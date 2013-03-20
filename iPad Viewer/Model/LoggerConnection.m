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

#include <netinet/in.h>
#import <objc/runtime.h>
#import "LoggerConnection.h"
#import "LoggerMessage.h"
#import "LoggerCommon.h"
#import "NullStringCheck.h"

char sConnectionAssociatedObjectKey = 1;

@implementation LoggerConnection
@synthesize delegate;
@synthesize reconnectionCount, connected;
@synthesize clientName, clientVersion, clientOSName, clientOSVersion, clientDevice, clientAddress, clientUDID;
@synthesize messageProcessingQueue;
@synthesize clientHash = _clientHash;

- (id)init
{
	if ((self = [super init]) != nil)
	{
		messageProcessingQueue = dispatch_queue_create("com.florentpillet.nslogger.messageProcessingQueue", NULL);
		//parentIndexesStack = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id)initWithAddress:(NSData *)anAddress
{
	if ((self = [super init]) != nil)
	{
		messageProcessingQueue = dispatch_queue_create("com.florentpillet.nslogger.messageProcessingQueue", NULL);
		//parentIndexesStack = [[NSMutableArray alloc] init];
		clientAddress = [anAddress copy];
	}
	return self;
}

- (void)dealloc
{
	dispatch_release(messageProcessingQueue);
	self.delegate = nil;
	//[parentIndexesStack release];
	[clientName release];
	[clientVersion release];
	[clientOSName release];
	[clientOSVersion release];
	[clientDevice release];
	[clientAddress release];
	[clientUDID release];
	[super dealloc];
}

- (BOOL)isNewRunOfClient:(LoggerConnection *)aConnection
{
	// Try to detect if a connection is a new run of an older, disconnected session
	// (goal is to detect restarts, so as to replace logs in the same window)

	// as well as still-up connections
	if (aConnection.connected)
		return NO;

	// check whether client info is the same
	BOOL (^isSame)(NSString *, NSString *) = ^(NSString *s1, NSString *s2)
	{
		if ((s1 == nil) != (s2 == nil))
			return NO;
		if (s1 != nil && ![s2 isEqualToString:s1])
			return NO;
		return YES;	// s1 and d2 either nil or same
	};

	if (!isSame(clientName, aConnection.clientName) ||
		!isSame(clientVersion, aConnection.clientVersion) ||
		!isSame(clientOSName, aConnection.clientOSName) ||
		!isSame(clientOSVersion, aConnection.clientOSVersion) ||
		!isSame(clientDevice, aConnection.clientDevice))
	{
		return NO;
	}
	
	// check whether address is the same, OR hardware ID (if present) is the same.
	// hardware ID wins (on desktop, iOS simulator can connect have different
	// addresses from run to run if the computer has multiple network interfaces / VMs installed
	if (clientUDID != nil && isSame(clientUDID, aConnection.clientUDID))
		return YES;
	
	if ((clientAddress != nil) != (aConnection.clientAddress != nil))
		return NO;

	if (clientAddress != nil)
	{
		// compare address blocks sizes (ipv4 vs. ipv6)
		NSUInteger addrSize = [clientAddress length];
		if (addrSize != [aConnection.clientAddress length])
			return NO;
		
		// compare ipv4 or ipv6 address. We don't want to compare the source port,
		// because it will change with each connection
		if (addrSize == sizeof(struct sockaddr_in))
		{
			struct sockaddr_in addra, addrb;
			[clientAddress getBytes:&addra];
			[aConnection.clientAddress getBytes:&addrb];
			if (memcmp(&addra.sin_addr, &addrb.sin_addr, sizeof(addra.sin_addr)))
				return NO;
		}
		else if (addrSize == sizeof(struct sockaddr_in6))
		{
			struct sockaddr_in6 addr6a, addr6b;
			[clientAddress getBytes:&addr6a];
			[aConnection.clientAddress getBytes:&addr6b];
			if (memcmp(&addr6a.sin6_addr, &addr6b.sin6_addr, sizeof(addr6a.sin6_addr)))
				return NO;
		}
		else if (![clientAddress isEqualToData:aConnection.clientAddress])
			return NO;		// we only support ipv4 and ipv6, so this should not happen
	}
	
	return YES;
}

- (void)messagesReceived:(NSArray *)msgs
{
	dispatch_async(messageProcessingQueue, ^{
		/* Code not functional yet
		 *
		NSRange range = NSMakeRange([messages count], [msgs count]);
		NSUInteger lastParent = NSNotFound;
		if ([parentIndexesStack count])
			lastParent = [[parentIndexesStack lastObject] intValue];
		
		for (NSUInteger i = 0, count = [msgs count]; i < count; i++)
		{
			// update cache for indentation
			LoggerMessage *message = [msgs objectAtIndex:i];
			switch (message.type)
			{
				case LOGMSG_TYPE_BLOCKSTART:
					[parentIndexesStack addObject:[NSNumber numberWithInt:range.location+i]];
					lastParent = range.location + i;
					break;
					
				case LOGMSG_TYPE_BLOCKEND:
					if ([parentIndexesStack count])
					{
						[parentIndexesStack removeLastObject];
						if ([parentIndexesStack count])
							lastParent = [[parentIndexesStack lastObject] intValue];
						else
							lastParent = NSNotFound;
					}
					break;
					
				default:
					if (lastParent != NSNotFound)
					{
						message.distanceFromParent = range.location + i - lastParent;
						message.indent = [parentIndexesStack count];
					}
					break;
			}
		}
		 *
		 */

		/*
		 stkim1_jan.19,2013
		 I find this is a perfect spot to pre-calculate data to cache
		 such as cell height, image size, text representation
		 */
		
		for(LoggerMessage *m in msgs)
		{
			[m textRepresentation];
			[m image];
			[m portraitHeight];

			// for now, landscape display is not supported
#ifdef SUPPORT_LADNSACPE_DISPLAY
			[m landscapeHeight];
#endif
		}

		if(LoggerCheckDelegate(delegate
							   ,@protocol(LoggerConnectionDelegate)
							   ,@selector(connection:didReceiveMessages:range:)))
		{
			/*
			 stkim1_jan.15,2013
			 range is not really necessary since I got rid of 'message' array
			 which stores LoggerMessages. Nonetheless, it will be here for 
			 a while due to 'parentIndexesStack' above.
			 */
			
			NSRange range;
			range = NSMakeRange(0, [msgs count]);
			[self.delegate connection:self didReceiveMessages:msgs range:range];
		}
	});
}

- (void)clientInfoReceived:(LoggerMessage *)message
{
	/*
	 * Adler32 hash : http://en.wikipedia.org/wiki/Adler-32
	 * Source Code : https://github.com/madler/zlib/blob/master/adler32.c#L65
	 */
	uLong hash = adler32(0L, Z_NULL, 0);
	
	NSDictionary *parts = message.parts;
	NSString *value = [parts objectForKey:[NSNumber numberWithInteger:PART_KEY_CLIENT_NAME]];
	
	if (!IS_NULL_STRING(value))
	{
		self.clientName = value;
		hash = adler32(hash, (Bytef *)[self.clientName UTF8String], (uInt)[self.clientName length]);
	}
	
	value = [parts objectForKey:[NSNumber numberWithInteger:PART_KEY_CLIENT_VERSION]];
	if (!IS_NULL_STRING(value))
	{
		self.clientVersion = value;
		hash = adler32(hash, (Bytef *)[self.clientVersion UTF8String], (uInt)[self.clientVersion length]);
	}
	
	value = [parts objectForKey:[NSNumber numberWithInteger:PART_KEY_OS_NAME]];
	if (!IS_NULL_STRING(value))
	{
		self.clientOSName = value;
		hash = adler32(hash, (Bytef *)[self.clientOSName UTF8String], (uInt)[self.clientOSName length]);
	}
	
	value = [parts objectForKey:[NSNumber numberWithInteger:PART_KEY_OS_VERSION]];
	if (!IS_NULL_STRING(value))
	{
		self.clientOSVersion = value;
		hash = adler32(hash, (Bytef *)[self.clientOSVersion UTF8String], (uInt)[self.clientOSVersion length]);
	}
	
	value = [parts objectForKey:[NSNumber numberWithInteger:PART_KEY_CLIENT_MODEL]];
	if (!IS_NULL_STRING(value))
	{
		self.clientDevice = value;
		hash = adler32(hash, (Bytef *)[self.clientDevice UTF8String], (uInt)[self.clientDevice length]);
	}
	
	value = [parts objectForKey:[NSNumber numberWithInteger:PART_KEY_UNIQUEID]];
	if (!IS_NULL_STRING(value))
	{
		self.clientUDID = value;
		hash = adler32(hash, (Bytef *)[self.clientUDID UTF8String], (uInt)[self.clientUDID length]);
	}

	_clientHash = hash;
	
	// make sure _client hash is non-nil hash
	assert(adler32(0L, Z_NULL, 0) != _clientHash);

	MTLog(@"client hash %lx",hash);
}

- (NSString *)clientAppDescription
{
	
	NSMutableString *s = [[[NSMutableString alloc] init] autorelease];
	if (clientName != nil)
		[s appendString:clientName];
	
	if (clientVersion != nil)
		[s appendFormat:@" %@", clientVersion];
	
	if (clientName == nil && clientVersion == nil)
		[s appendString:NSLocalizedString(@"<unknown>", @"")];
	
	if (clientOSName != nil && clientOSVersion != nil)
		[s appendFormat:@"%@(%@ %@)", [s length] ? @" " : @"", clientOSName, clientOSVersion];
	
	
	else if (clientOSName != nil)
		[s appendFormat:@"%@(%@)", [s length] ? @" " : @"", clientOSName];

	return s;
}

- (NSString *)clientAddressDescription
{
	// subclasses should implement this
	return nil;
}

- (NSString *)clientDescription
{
	// enforce thread safety (only on main thread)
	//assert([NSThread isMainThread]);
	return [NSString stringWithFormat:@"%@ @ %@", [self clientAppDescription], [self clientAddressDescription]];
}

#if 0
- (NSString *)status
{
	// status is being observed by LoggerStatusWindowController and changes once
	// when the connection gets disconnected
	NSString *format;
	if (connected)
		format = NSLocalizedString(@"%@ connected", @"");
	else
		format = NSLocalizedString(@"%@ disconnected", @"");
	if ([NSThread isMainThread])
		return [NSString stringWithFormat:format, [self clientDescription]];

	__block NSString *status;
	
#warning need to change this queue to transport manage queue
	dispatch_sync(dispatch_get_main_queue(), ^{
		status = [[NSString stringWithFormat:format, [self clientDescription]] retain];
	});
	return [status autorelease];
}
#endif

- (void)setConnected:(BOOL)newConnected
{
	if (connected != newConnected)
	{
		connected = newConnected;

		if(!connected &&
		   LoggerCheckDelegate(delegate
							   ,@protocol(LoggerConnectionDelegate)
							   ,@selector(remoteDisconnected:)))
		{
			[delegate remoteDisconnected:self];
		}
	}
}

- (void)shutdown
{
	self.connected = NO;
}
@end
