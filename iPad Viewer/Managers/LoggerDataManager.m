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

#import "LoggerDataManager.h"
#import "NSManagedObjectContext+FetchAdditions.h"
#import "NSFileManager+DirectoryLocations.h"
#import "SynthesizeSingleton.h"

#import "LoggerMessageData.h"
#import "LoggerNativeMessage.h"
#include "time_converter.h"

@interface LoggerDataManager()
@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly) NSManagedObjectContext *messageProcessContext;
@property (nonatomic, readonly) NSManagedObjectContext *messageSaveContext;
-(void)_runMessageSaveChain:(NSError **)aSaveError;
@end

@implementation LoggerDataManager
{
	NSManagedObjectModel *_managedObjectModel;
	NSPersistentStoreCoordinator *_persistentStoreCoordinator;

	// The root disk save context
	NSManagedObjectContext *_messageSaveContext;
	
	// Secondary display/UI context. NSFetchRequestController takes
	// this to display message on UITableViewCell
	NSManagedObjectContext *_messageDisplayContext;
	
	// finally, mesage process queue and context
	NSManagedObjectContext *_messageProcessContext;
	dispatch_queue_t	_messageProcessQueue;
}
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize messageDisplayContext = _messageDisplayContext;
@synthesize messageProcessContext = _messageProcessContext;
@synthesize messageSaveContext = _messageSaveContext;

SYNTHESIZE_SINGLETON_FOR_CLASS_WITH_ACCESSOR(LoggerDataManager,sharedDataManager);

-(id)init
{
	self = [super init];
	if(self)
	{
		
		// initialize resposible MOCs to wake up.
		[self managedObjectModel];
		[self persistentStoreCoordinator];
		
		// root disk save context
		[self messageSaveContext];
		
		// Secondary display/UI context. NSFetchRequestController takes
		// this to display message on UITableViewCell
		[self messageDisplayContext];

		// finally, mesage process queue and context
		_messageProcessQueue = \
			dispatch_queue_create("com.colorfulglue.nslogger-ipad",NULL);
		
		dispatch_sync(_messageProcessQueue, ^{
			[self messageProcessContext];
		});
		
		// very first save operation to initialize PSC
		dispatch_sync(_messageProcessQueue, ^{

			MTLog(@"message process MOC save");

			__block NSError *error = nil;
			__block BOOL	isSavedOk = NO;

			isSavedOk = [[self messageProcessContext] save:&error];
			
			if(!isSavedOk || error != nil)
			{
				MTLog(@"we have a save error on process MOC %@",[error localizedFailureReason]);
			}
			else
			{

				MTLog(@"message display MOC save");
				[[self messageDisplayContext]
				 performBlockAndWait:^{
					 
					 isSavedOk = [[self messageDisplayContext] save:&error];
					 
					 if(!isSavedOk || error != nil)
					 {
						 MTLog(@"we have a save error on process MOC %@",[error localizedFailureReason]);
					 }
					 else
					 {
						 // initialize PSC on disk
						 MTLog(@"message write MOC save");
						 [[self messageSaveContext]
						  performBlockAndWait:^{
							  isSavedOk = [[self messageSaveContext] save:&error];
							  
							  if(!isSavedOk || error != nil)
							  {
								 MTLog(@"we have a save error on process MOC %@",[error localizedFailureReason]);
							  }
							  
						  }];
					 }
				 }];
			}
		});
		
	}
	return  self;
}


-(NSManagedObjectModel *)managedObjectModel
{
	if(_managedObjectModel == nil)
	{
		_managedObjectModel = \
		[[NSManagedObjectModel alloc] initWithContentsOfURL:
		 [[NSBundle mainBundle] URLForResource:@"LoggerMessages"
								 withExtension:@"momd"]
		 ];
	}
	return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
	NSPersistentStore *store __attribute__((unused)) = nil;
	//#pragma unused(store)

	if (_persistentStoreCoordinator != nil)
	{
		return _persistentStoreCoordinator;
	}
	
	_persistentStoreCoordinator = \
		[[NSPersistentStoreCoordinator alloc]
		 initWithManagedObjectModel:[self managedObjectModel]];

	NSString *storePath = \
		[[[NSFileManager defaultManager] applicationDocumentsDirectory]
		 stringByAppendingPathComponent: @"LoggerData.sqlite"];

	NSDictionary *options = \
		@{NSMigratePersistentStoresAutomaticallyOption:[NSNumber numberWithBool:YES]
		,NSInferMappingModelAutomaticallyOption:[NSNumber numberWithBool:YES]
		,NSReadOnlyPersistentStoreOption:[NSNumber numberWithBool:NO]};
	
	NSError *error;
	
	store = \
		[_persistentStoreCoordinator
		 addPersistentStoreWithType:NSSQLiteStoreType
		 configuration:nil
		 URL:[NSURL fileURLWithPath:storePath]
		 options:options
		 error:&error];
	
	return _persistentStoreCoordinator;
}

//------------------------------------------------------------------------------
#pragma mark - MOC setup
//------------------------------------------------------------------------------

/*
 This MOC is for writing to PSC. It has its own GCD queue, and you can tell it
 to do anything you want regarding to writing operation
 */
-(NSManagedObjectContext *)messageSaveContext
{
	NSPersistentStoreCoordinator *coordinator = nil;

	if(_messageSaveContext != nil)
	{
		return _messageSaveContext;
	}

	coordinator = [self persistentStoreCoordinator];
	MTAssert(coordinator != nil, @"PSC must never be nil atm");
	
	if(coordinator != nil)
	{
		// this context must  be created from main thread
		assert([NSThread isMainThread]);

		_messageSaveContext = \
			[[NSManagedObjectContext alloc]
			 initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		
		[_messageSaveContext
		 performBlockAndWait:^{
			 [_messageSaveContext setPersistentStoreCoordinator:coordinator];
			 [_messageSaveContext setUndoManager:nil];
		 }];
	}
	
	return _messageSaveContext;
}

/*
 this is displaying MOC. It will be connected to NSFetchResultController.
 */
- (NSManagedObjectContext *)messageDisplayContext
{
	
	if (_messageDisplayContext != nil)
	{
		return _messageDisplayContext;
	}

	NSManagedObjectContext *saveContext = [self messageSaveContext];
	MTAssert(saveContext != nil, @"A parent MOC must not be nil");

	if(saveContext != nil)
	{
		// this context must  be created from main thread
		assert([NSThread isMainThread]);
		
		_messageDisplayContext = \
			[[NSManagedObjectContext alloc]
			 initWithConcurrencyType:NSMainQueueConcurrencyType];
		[_messageDisplayContext setParentContext:saveContext];
		[_messageDisplayContext setUndoManager:nil];
	}

	return _messageDisplayContext;
}

// A mesage process queue and context
- (NSManagedObjectContext *)messageProcessContext
{
/*
 message processing context must be invoked within messageProcessQueue only.
 dispatch_get_current_queue is depricated from ios 6.0. so that's fine to use 
 for a while
 */
	assert(dispatch_get_current_queue() == _messageProcessQueue);
	
	if(_messageProcessContext != nil)
	{
		return _messageProcessContext;
	}
	
	NSManagedObjectContext *displayContext = [self messageDisplayContext];
	MTAssert(displayContext != nil, @"A display MOC should not be nil");

	if(displayContext != nil)
	{
		_messageProcessContext = \
			[[NSManagedObjectContext alloc]
			 initWithConcurrencyType:NSConfinementConcurrencyType];
		[_messageProcessContext setParentContext:displayContext];
		[_messageProcessContext setUndoManager:nil];
	}
	
	return _messageProcessContext;
}


//------------------------------------------------------------------------------
#pragma mark - save message chain
//------------------------------------------------------------------------------
-(void)_runMessageSaveChain:(NSError **)aSaveError
{
	assert(dispatch_get_current_queue() == _messageProcessQueue);
	
	__block NSError *error = nil;
	__block BOOL	isSavedOk = NO;
	
	isSavedOk = [[self messageProcessContext] save:&error];
	
	if(!isSavedOk || error != nil)
	{
		MTLog(@"we have a save error on message_q <%d>[%@](%@)",isSavedOk,[error domain],[error localizedDescription]);
	}
	else
	{
		[[self messageDisplayContext]
		 performBlock:^{
			 
			 isSavedOk = [[self messageDisplayContext] save:&error];
			 
			 if(!isSavedOk || error != nil)
			 {
				 MTLog(@"we have a save error on display_q %@",[error localizedFailureReason]);
			 }
			 else
			 {
				 // initialize PSC on disk
				 [[self messageSaveContext]
				  performBlock:^{

					  isSavedOk = [[self messageSaveContext] save:&error];
					  
					  if(!isSavedOk || error != nil)
					  {
						  MTLog(@"we have a save error on save_q %@",[error localizedFailureReason]);
					  }
					  
				  }];
			 }
		 }];
	}
}

//------------------------------------------------------------------------------
#pragma mark - save message chain
//------------------------------------------------------------------------------
- (void)connection:(LoggerConnection *)theConnection
didReceiveMessages:(NSArray *)theMessages
			 range:(NSRange)rangeInMessagesList
{
	dispatch_async(_messageProcessQueue, ^{
		@autoreleasepool
		{
			
			NSUInteger end = [theMessages count];
			
			@try
			{
				
				for (int i = 0; i < end; i++)
				{
					LoggerNativeMessage *aMessage = \
						[theMessages objectAtIndex:i];

					LoggerMessageData *messageData =\
						[NSEntityDescription
						 insertNewObjectForEntityForName:@"LoggerMessageData"
						 inManagedObjectContext:[self messageProcessContext]];
					
					struct timeval tm = [aMessage timestamp];

					[messageData setTimestamp:		convert_timeval(&tm)];
					[messageData setTag:			[aMessage tag]];
					[messageData setFilename:		[aMessage filename]];
					[messageData setFunctionName:	[aMessage functionName]];
					
					[messageData setSequence:		[aMessage sequence]];
					[messageData setThreadID:		[aMessage threadID]];
					[messageData setLineNumber:		[aMessage lineNumber]];

					[messageData setLevel:			[aMessage level]];
					[messageData setType:			[aMessage type]];
					[messageData setContentsType:	[aMessage contentsType]];

					[messageData setImageSize:		NSStringFromCGSize([aMessage imageSize])];

					[messageData setMessageText:	[aMessage messageText]];
					[messageData setMessageType:	[aMessage messageType]];
					[messageData setTextRepresentation:[aMessage textRepresentation]];
					
					[messageData setPortraitHeight:	[aMessage portraitHeight]];
					[messageData setLandscapeHeight:[aMessage landscapeHeight]];
				}
			}
			@finally {
				// since we've completed copying messages into coredata,
				[self _runMessageSaveChain:nil];
			}
		}
	});
}

// handle disconnection
- (void)remoteDisconnected:(LoggerConnection *)theConnection
{
	// handle connection specific logic
	dispatch_async(_messageProcessQueue, ^{


		// notify views related to the connection
		dispatch_async(dispatch_get_main_queue(),^{
			[[NSNotificationCenter defaultCenter]
			 postNotificationName:kShowStatusInStatusWindowNotification
			 object:self];
		});
	});
}

@end
