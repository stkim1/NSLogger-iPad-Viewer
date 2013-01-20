/*
 * LoggerTransport.m
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
#import "LoggerTransport.h"
#import "LoggerTransportManager.h"

@implementation LoggerTransport
@synthesize transManager;
@synthesize prefManager;
@synthesize certManager;
@synthesize connections;
@synthesize secure, active, ready, failed, failureReason;

- (id)init
{
	if ((self = [super init]) != nil)
	{
		connections = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
	self.transManager = nil;
	self.prefManager = nil;
	self.certManager = nil;
	
	[failureReason release];
	[connections release];
	[super dealloc];
}

- (void)addConnection:(LoggerConnection *)aConnection
{
	[connections addObject:aConnection];
}

- (void)removeConnection:(LoggerConnection *)aConnection
{
	if ([connections containsObject:aConnection])
	{
		[aConnection shutdown];
		[connections removeObject:aConnection];
		
		if(LoggerCheckDelegate(transManager
							   ,@protocol(LoggerTransportDelegate)
							   ,@selector(transport:removeConnection:)))
		{
			[transManager
			 transport:self
			 removeConnection:aConnection];
		}
	}
}

- (void)attachConnectionToManager:(LoggerConnection *)aConnection
{
	MTLog(@"setup new connection [%@]",aConnection);
	
	if(LoggerCheckDelegate(transManager
						   ,@protocol(LoggerTransportDelegate)
						   ,@selector(transport:didEstablishConnection:)))
	{
		[transManager
		 transport:self
		 didEstablishConnection:aConnection];
	}
}

- (void)presentErrorToManager:(NSError *)anError
{
	[self.transManager reportTransportError:anError];
}

- (void)startup
{
	//  subclasses should implement this
}

- (void)shutdown
{
	// subclasses should implement this
}

- (void)restart
{
	// subclasses should implement this
}

- (NSString *)transportInfoString
{
	// subclasses should implement this, LoggerStatusWindowController uses it
	return nil;
}

- (NSString *)transportStatusString
{
	// subclasses should implement this, LoggerStatusWindowController uses it
	return nil;
}

//------------------------------------------------------------------------------
#pragma mark - logger connection delegate
//------------------------------------------------------------------------------
// method that may not be called on main thread
- (void)connection:(LoggerConnection *)theConnection didReceiveMessages:(NSArray *)theMessages range:(NSRange)rangeInMessagesList
{
	if(LoggerCheckDelegate(transManager
						   ,@protocol(LoggerTransportDelegate)
						   ,@selector(transport:connection:didReceiveMessages:range:)))
	{
		[transManager
		 transport:self
		 connection:theConnection
		 didReceiveMessages:theMessages
		 range:rangeInMessagesList];
	}
}

// method report to the according transport
- (void)remoteDisconnected:(LoggerConnection *)theConnection
{
	
}

@end
