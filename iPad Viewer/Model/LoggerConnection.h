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


#import <Foundation/Foundation.h>
#import "LoggerConstApp.h"
#import "LoggerConstController.h"
#import <zlib.h>

@class LoggerConnection, LoggerMessage;

// -----------------------------------------------------------------------------
// LoggerConnectionDelegate protocol
// -----------------------------------------------------------------------------
@protocol LoggerConnectionDelegate <NSObject>

- (void)connection:(LoggerConnection *)theConnection
didEstablishWithMessage:(LoggerMessage *)theMessage;

// method that may not be called on main thread
- (void)connection:(LoggerConnection *)theConnection
didReceiveMessages:(NSArray *)theMessages
			 range:(NSRange)rangeInMessagesList;

-(void)connection:(LoggerConnection *)theConnection
didDisconnectWithMessage:(LoggerMessage *)theMessage;

@end

// -----------------------------------------------------------------------------
// NSLoggerConnection class
// -----------------------------------------------------------------------------
@interface LoggerConnection : NSObject
{
	id<LoggerConnectionDelegate> delegate;
    
	// Client info, as transmitted
	NSString			*clientName;
	NSString			*clientVersion;
	NSString			*clientOSName;
	NSString			*clientOSVersion;
	NSString			*clientDevice;
	NSString			*clientUDID;
    

	// stkim1_jan.22,2013
	// when new client info arrives, a new hash value will be generated based on
	// the values above with alder32() hash function.
	// this hash will give gives us a key to find client info object in coredata
	uLong				_clientHash;

	// depends on the underlying protocol
	NSData				*clientAddress;
    
	// during messages receive, use this to quickly locate parent indexes in groups
	//NSMutableArray		*parentIndexesStack;
	
	dispatch_queue_t	messageProcessingQueue;
	
	//when a reconnection is detected (same client, disconnects then reconnects),
	//the # reconnection for this connection
	int					reconnectionCount;

	BOOL				connected;
}
// stkim1_jan.15,2013
// retained delegate could cause retain cycle. replaced with assign,
@property (assign) id <LoggerConnectionDelegate> delegate;

@property (nonatomic, retain) NSString				*clientName;
@property (nonatomic, retain) NSString				*clientVersion;
@property (nonatomic, retain) NSString				*clientOSName;
@property (nonatomic, retain) NSString				*clientOSVersion;
@property (nonatomic, retain) NSString				*clientDevice;
@property (nonatomic, retain) NSString				*clientUDID;
@property (nonatomic, readonly) uLong				clientHash;
@property (nonatomic, readonly) NSData				*clientAddress;

@property (nonatomic, assign) int					reconnectionCount;
@property (nonatomic, assign) BOOL					connected;
@property (nonatomic, readonly) dispatch_queue_t	messageProcessingQueue;

- (id)initWithAddress:(NSData *)anAddress;
- (void)shutdown;

- (void)clientInfoReceived:(LoggerMessage *)message;
- (void)messagesReceived:(NSArray *)msgs;
- (void)clientDisconnectWithMessage:(LoggerMessage *)message;

- (NSString *)clientAppDescription;
- (NSString *)clientAddressDescription;
- (NSString *)clientDescription;

#ifdef CHECK_DUPLICATED_CONNECTION
- (BOOL)isNewRunOfClient:(LoggerConnection *)aConnection;
#endif

@end

extern char sConnectionAssociatedObjectKey;
