/*
 *
 * BSD license follows (http://www.opensource.org/licenses/bsd-license.php)
 *
 * Copyright (c) 2012-2013 Sung-Taek, Kim <stkim1@colorfulglue.com> All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of  source code  must retain  the above  copyright notice,
 * this list of  conditions and the following  disclaimer. Redistributions in
 * binary  form must  reproduce  the  above copyright  notice,  this list  of
 * conditions and the following disclaimer  in the documentation and/or other
 * materials  provided with  the distribution.  Neither the  name of  Sung-Ta
 * ek kim nor the names of its contributors may be used to endorse or promote
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


#import "LoggerTransportManager.h"
#import "LoggerCertManager.h"
#import "LoggerNativeTransport.h"
#import "SynthesizeSingleton.h"
#import <zlib.h>

@interface LoggerTransportManager()
@property (nonatomic, retain) LoggerCertManager *certManager;
@property (nonatomic, retain) NSMutableArray	*transports;
-(void)_startStopTransports;
@end

@implementation LoggerTransportManager
{
	LoggerCertManager			*_certManager;
	LoggerPreferenceManager		*_prefManager;
	NSMutableArray				*_transports;
	LoggerDataManager			*_dataManager;
	
}
@synthesize prefManager = _prefManager;
@synthesize certManager = _certManager;
@synthesize transports = _transports;
@synthesize dataManager = _dataManager;

SYNTHESIZE_SINGLETON_FOR_CLASS_WITH_ACCESSOR(LoggerTransportManager,sharedTransportManager);

- (id)init
{
	self = [super init];
	if (self)
	{
		if(_certManager == nil)
		{
			NSError *error = nil;
			LoggerCertManager *aCertManager = [[LoggerCertManager alloc] init];
			
			// we load server cert at this point to reduce any delay might happen later
			// in transport object.
			[aCertManager loadEncryptionCertificate:&error];
#warning alert cert loading error
			_certManager = aCertManager;
		}
		
		if(_transports == nil)
		{
			_transports = [[NSMutableArray alloc] initWithCapacity:0];
		}
	}

    return self;
}

-(void)createTransports
{
	// unencrypted Bonjour service (for backwards compatibility)
	LoggerNativeTransport *t = [[LoggerNativeTransport alloc] init];
	t.transManager = self;
	t.prefManager = [self prefManager];
	t.certManager = self.certManager;
	t.publishBonjourService = YES;
	t.secure = NO;
	[self.transports addObject:t];
	[t release];
	
	// SSL Bonjour service
	t = [[LoggerNativeTransport alloc] init];
	t.transManager = self;
	t.prefManager = [self prefManager];
	t.certManager = self.certManager;
	t.publishBonjourService = YES;
	t.secure = YES;
	[self.transports addObject:t];
	[t release];

	// Direct TCP/IP service (SSL mandatory)
	t = [[LoggerNativeTransport alloc] init];
	t.transManager = self;
	t.prefManager = [self prefManager];
	t.certManager = self.certManager;
	t.listenerPort = [self.prefManager directTCPIPResponderPort];
	t.secure = YES;
	[self.transports addObject:t];
	[t release];
}

-(void)destoryTransports
{
	
}

-(void)_startStopTransports
{
	NSLog(@"%@",NSStringFromSelector(_cmd));
	// Start and stop transports as needed
	for (LoggerTransport *transport in self.transports)
	{
		if ([transport isKindOfClass:[LoggerNativeTransport class]])
		{
			LoggerNativeTransport *t = (LoggerNativeTransport *)transport;
			if (t.publishBonjourService)
			{
				if ([self.prefManager shouldPublishBonjourService])
					[t restart];
				else if (t.active)
					[t shutdown];
			}
			else
			{
				if ([self.prefManager hasDirectTCPIPResponder])
					[t restart];
				else
					[t shutdown];
			}
		}
	}
}

-(void)startStopTransports
{
	NSLog(@"%@",NSStringFromSelector(_cmd));
	// start transports
	[self performSelector:@selector(_startStopTransports) withObject:nil afterDelay:0];
}

// -----------------------------------------------------------------------------
#pragma mark - Handling Connection from Transport
// -----------------------------------------------------------------------------
- (void)reportTransportError:(NSError *)anError
{
	dispatch_sync(dispatch_get_main_queue(), ^{
		MTLog(@"we need to report error");
#warning report error
	});
}

// -----------------------------------------------------------------------------
#pragma mark - Logger Transport Delegate
// -----------------------------------------------------------------------------
// transport report new connection to manager
- (void)transport:(LoggerTransport *)theTransport
didEstablishConnection:(LoggerConnection *)theConnection
{
	MTLog(@"setup new connection [%@]",theConnection);

	[_dataManager
	 transport:theTransport
	 didEstablishConnection:theConnection];
}

// method that may not be called on main thread
- (void)transport:(LoggerTransport *)theTransport
	   connection:(LoggerConnection *)theConnection
didReceiveMessages:(NSArray *)theMessages
			range:(NSRange)rangeInMessagesList
{
	//MTLog(@"Connection [%@ ] receieve messages (%d) for range (%d~%d)",theConnection,[theMessages count],rangeInMessagesList.location, rangeInMessagesList.length);

	[_dataManager
	 transport:theTransport
	 connection:theConnection
	 didReceiveMessages:theMessages
	 range:rangeInMessagesList];
}

- (void)transport:(LoggerTransport *)theTransport
didDisconnectRemote:(LoggerConnection *)theConnection
{
	[_dataManager transport:theTransport didDisconnectRemote:theConnection];
}

- (void)transport:(LoggerTransport *)theTransport
 removeConnection:(LoggerConnection *)theConnection
{
	[_dataManager transport:theTransport removeConnection:theConnection];
}


@end
