//
//  LoggerConnectionManager.m
//  ipadnslogger
//
//  Created by Almighty Kim on 11/5/12.
//  Copyright (c) 2012 Colorful Glue. All rights reserved.
//

#import "LoggerTransportManager.h"
#import "LoggerCertManager.h"
#import "LoggerNativeTransport.h"
#import "SynthesizeSingleton.h"

@interface LoggerTransportManager()
@property (nonatomic, retain) LoggerCertManager *certManager;
@property (nonatomic, retain) NSMutableArray	*transports;
@property (nonatomic, readonly) NSMutableArray	*connections;
@property (nonatomic, readonly) dispatch_queue_t connectionManageQueue;
-(void)_startStopTransports;
@end

@implementation LoggerTransportManager
{
	LoggerCertManager			*_certManager;
	LoggerPreferenceManager		*_prefManager;
	NSMutableArray				*_transports;
	LoggerDataManager			*_dataManager;
	
	NSMutableArray				*_connections;
	dispatch_queue_t			_connectionManageQueue;
}
@synthesize prefManager = _prefManager;
@synthesize certManager = _certManager;
@synthesize transports = _transports;
@synthesize dataManager = _dataManager;
@synthesize connections = _connections;
@synthesize connectionManageQueue = _connectionManageQueue;

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
		
		_connectionManageQueue = \
			dispatch_queue_create("com.colorfulglue.connectionmanagerqueue"
								  ,DISPATCH_QUEUE_SERIAL);

		dispatch_sync(_connectionManageQueue, ^{
			_connections = [[NSMutableArray alloc] initWithCapacity:0];
		});
		
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
	NSLog(@"setup new connection [%@]",theConnection);

#if 0
	// Go through all open documents,
	// Detect reconnection from a previously disconnected client
	NSDocumentController *docController = [NSDocumentController sharedDocumentController];
	for (LoggerDocument *doc in [docController documents])
	{
		if (![doc isKindOfClass:[LoggerDocument class]])
			continue;
		
		for (LoggerConnection *c in doc.attachedLogs)
		{
			if (c != aConnection && [aConnection isNewRunOfClient:c])
			{
				// recycle this document window, bring it to front
				aConnection.reconnectionCount = ((LoggerConnection *)[doc.attachedLogs lastObject]).reconnectionCount + 1;
				[doc addConnection:aConnection];
				return;
			}
		}
	}
	
	// Instantiate a new window for this connection
	LoggerDocument *doc = [[LoggerDocument alloc] initWithConnection:aConnection];
	[docController addDocument:doc];
	[doc makeWindowControllers];
	[doc showWindows];
	[doc release];
#endif

	dispatch_async(_connectionManageQueue, ^{
		
		int reconnectionCount = 0;
		
		for (LoggerConnection *conn in _connections)
		{
			if((conn != theConnection) && [theConnection isNewRunOfClient:conn])
			{
				if(reconnectionCount <= [conn reconnectionCount])
				{
					reconnectionCount = [conn reconnectionCount] + 1;
				}
			}
		}
		
		// add newly arrived one into connection pool
		[_connections addObject:theConnection];

		//we've found an existing connection.
		//increase reconnection count and notify its reconnection to UI
		// Modifying reconnection count should only happen in this queue.
		if(reconnectionCount != 0)
		{
#warning !Possible race condition
			// it is unprotected property that if you try to change in other
			// thread, you will face a race condition
			//stkim1_jan.17,2013

			[theConnection setReconnectionCount:reconnectionCount];
		
			dispatch_async(dispatch_get_main_queue(), ^{
				MTLog(@"a connection gets recycled %d", reconnectionCount);
#if 0
				[[NSNotificationCenter defaultCenter]
				 postNotificationName:kShowStatusInStatusWindowNotification
				 object:theConnection];
#endif
			});
		}
		else
		{
			// report new connection to UI
			dispatch_async(dispatch_get_main_queue(), ^{
				MTLog(@"new connection has established");
#if 0
				[[NSNotificationCenter defaultCenter]
				 postNotificationName:kShowStatusInStatusWindowNotification
				 object:theConnection];
#endif
			});
		}
	});
}

// method that may not be called on main thread
- (void)transport:(LoggerTransport *)theTransport
	   connection:(LoggerConnection *)theConnection
didReceiveMessages:(NSArray *)theMessages
			range:(NSRange)rangeInMessagesList
{
	//MTLog(@"Connection [%@ ] receieve messages (%d) for range (%d~%d)",theConnection,[theMessages count],rangeInMessagesList.location, rangeInMessagesList.length);

	[_dataManager
	 connection:theConnection
	 didReceiveMessages:theMessages
	 range:rangeInMessagesList];
}

- (void)transport:(LoggerTransport *)theTransport
didDisconnectRemote:(LoggerConnection *)theConnection
{
	
}

- (void)transport:(LoggerTransport *)theTransport
 removeConnection:(LoggerConnection *)theConnection
{
#warning say, we remove an object of lastest run. How do we find the # of runs for next connection?
	dispatch_async(_connectionManageQueue, ^{
		[_connections removeObject:theConnection];
	});
}


@end
