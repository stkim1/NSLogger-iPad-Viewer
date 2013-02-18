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


#import "LoggerDataStorage.h"
#import "NullStringCheck.h"
#import "LoggerDataWrite.h"
#import "LoggerDataRead.h"
#import "LoggerDataDelete.h"
#import "LoggerDataEntry.h"
#import "SynthesizeSingleton.h"

@interface LoggerDataStorage()
@property (nonatomic, readonly) dispatch_queue_t		dataEntryQueue;
@property (nonatomic, readonly) dispatch_queue_t		operationQueue;
@property (nonatomic, readonly) dispatch_queue_t		dispatcherQueue;

@property (nonatomic, readonly) NSMutableDictionary		*dataCache;

@property (nonatomic, readonly) NSMutableArray			*writeOperationReserve;
@property (nonatomic, readonly) NSMutableArray			*readOperationReserve;
@property (nonatomic, readonly) NSMutableArray			*writeOperationSlot;
@property (nonatomic, readonly) NSMutableArray			*readOperationSlot;

@property (nonatomic, retain)	NSString				*basepath;
@property (nonatomic, readonly) int						cpuCount;
//------------------------------------------------------------------------------
-(void)_enoperationQueue:(LoggerDataOperation *)anOperation;
-(void)_deoperationQueue:(LoggerDataOperation *)anOperation;
@end

@implementation LoggerDataStorage
{
	// this queue will handle instruction dependency issue,
	// enqueue instruction to instruction queue, and callback to UI-
	dispatch_queue_t		_dataEntryQueue;
	
	// this queue manages # of concurrent instructions,
	// and instruction queue
	dispatch_queue_t		_operationQueue;

	// this queue will concurrently dispatch actual instructions
	dispatch_queue_t		_dispatcherQueue;

	// this is the cache pool that contains binary data
	NSMutableDictionary		*_dataCache;
	
	// read instruction reservation
	NSMutableArray			*_writeOperationReserve;
	
	// write instruction reservation (write/delete)
	NSMutableArray			*_readOperationReserve;

	// since we're to operation within instruction queue,
	// we don't want this to be volatile, which would consume more CPU cycles
	// we want this to be non-volatile, confined in a specific queue,
	// and runs blazing fast.
	NSMutableArray			*_readOperationSlot;
	NSMutableArray			*_writeOperationSlot;
	
	// a path where directory operation must based on
	NSString				*_basepath;
	
	int						_cpuCount;
}
@synthesize dataEntryQueue = _dataEntryQueue;
@synthesize operationQueue = _operationQueue;
@synthesize dispatcherQueue = _dispatcherQueue;
@synthesize readOperationSlot = _readOperationSlot;
@synthesize writeOperationSlot = _writeOperationSlot;

@synthesize dataCache = _dataCache;
@synthesize writeOperationReserve = _writeOperationReserve;
@synthesize readOperationReserve = _readOperationReserve;
@synthesize basepath = _basepath;
@synthesize cpuCount = _cpuCount;

SYNTHESIZE_SINGLETON_FOR_CLASS_WITH_ACCESSOR(LoggerDataStorage,sharedDataStorage);

-(id)init
{
	self = [super init];
	if(self != nil)
	{
		// manages instruction dependency, create instruction, take
		// read/write/delete/purge command from other components
		_dataEntryQueue =\
			dispatch_queue_create("com.colorfulglue.loggerdatastorage.datamanagerqueue"
								  ,DISPATCH_QUEUE_SERIAL);
		
		// read/write/delete/purge instruction handling queue
		_operationQueue = \
			dispatch_queue_create("com.colorfulglue.loggerdatastorage.operationqueue"
								  ,DISPATCH_QUEUE_SERIAL);

		// process instruction
		_dispatcherQueue = \
			dispatch_queue_create("com.colorfulglue.loggerdatastorage.dispatcherqueue"
								  ,DISPATCH_QUEUE_CONCURRENT);

		
		dispatch_sync(_dataEntryQueue, ^{
			NSArray *paths = \
				NSSearchPathForDirectoriesInDomains(NSDocumentDirectory
													,NSUserDomainMask, YES);
			NSString *path = \
				([paths count] > 0) ? [paths objectAtIndex:0] : nil;
			
			NSString *targetPath = \
				(path) ? [NSString stringWithFormat:@"%@/",path] : nil;
			
			_basepath = [targetPath retain];

			_dataCache = \
				[[NSMutableDictionary alloc] initWithCapacity:0];
		});
		
		
		int cpus = [[NSProcessInfo processInfo] processorCount];
		
		dispatch_sync(_operationQueue, ^{
			_cpuCount = cpus;
			
			_writeOperationReserve =\
				[[NSMutableArray alloc] initWithCapacity:4];
			
			_readOperationReserve =\
				[[NSMutableArray alloc] initWithCapacity:4];
			
			_readOperationSlot =\
				[[NSMutableArray alloc] initWithCapacity:_cpuCount];
			
			_writeOperationSlot = \
				[[NSMutableArray alloc] initWithCapacity:_cpuCount];
		});
		
		
	}
	return self;
}

-(void)dealloc
{
	// need to dealloc arrays
	dispatch_sync(_dataEntryQueue, ^{
		[_dataCache removeAllObjects],[_dataCache release],_dataCache = nil;
		[_basepath release],_basepath = nil;
	});
	
	dispatch_sync(_operationQueue, ^{
		[_readOperationReserve removeAllObjects];
		[_readOperationReserve release];
		_readOperationReserve = nil;
		
		[_writeOperationReserve removeAllObjects];
		[_writeOperationReserve release];
		_writeOperationReserve = nil;
		
		[_readOperationSlot removeAllObjects];
		[_readOperationSlot release];
		_readOperationSlot = nil;
		
		[_writeOperationSlot removeAllObjects];
		[_writeOperationSlot release];
		_writeOperationSlot = nil;
	});
	
	dispatch_release(_dataEntryQueue);
	dispatch_release(_dispatcherQueue);
    dispatch_release(_operationQueue);
	[super dealloc];
}


-(void)writeData:(NSData *)aData toPath:(NSString *)aFilepath
{
	MTLogVerify(@"%s data # %d path %@",__PRETTY_FUNCTION__,[aData length],aFilepath);
	return;

	
	if(IS_NULL_STRING(aFilepath))
		return;

	if(aData == nil || ![aData length])
		return;

	dispatch_async(_dataEntryQueue, ^{
		@autoreleasepool {
			
			//[self dataCache]
			LoggerDataEntry *entry = \
				[[LoggerDataEntry alloc]
				 initWithFilepath:aFilepath];
			[entry setData:aData];
			
			LoggerDataWrite	*writeOperation = \
				[[LoggerDataWrite alloc]
				  initWithData:aData
				  basepath:[self basepath]
				  filePath:aFilepath
			      dirPartOfFilepath:[entry dirOfFilepath]
				  callback_queue:[self dataEntryQueue]
				  callback:^(LoggerDataOperation *dataOperation, int error, NSData *data) {
					MTLogInfo(@"%@ success %@ error %d",aFilepath,(!error?@"YES":@"NO"),error);

					// handle success
					if(error == 0)
					{
					}
					// handle error here
					else
					{
					}

					[self _deoperationQueue:dataOperation];
					[[entry operationQueue] removeObject:dataOperation];
				 }];

			[[entry operationQueue] addObject:writeOperation];
			
			
			// set entry for filepath
			[[self dataCache] setObject:entry forKey:aFilepath];
			[self _enoperationQueue:writeOperation];

			[entry release],entry = nil;
			[writeOperation release], writeOperation = nil;
		}
	});
}

-(void)readDataFromPath:(NSString *)aPath forResult:(void (^)(NSData *aData))aResultHandler
{
	MTLogVerify(@"%s aPath %@",__PRETTY_FUNCTION__,aPath);

	if(IS_NULL_STRING(aPath))
	{
		aResultHandler(nil);
		return;
	}

	dispatch_async(_dataEntryQueue, ^{
		
		LoggerDataEntry *entry = [[self dataCache] objectForKey:aPath];
		
		if(entry != nil && [entry data] != nil)
		{
			MTLogInfo(@"[READ] Cache Found %@ success YES",aPath);

			NSData *cachedData = [entry data];
			dispatch_async(dispatch_get_main_queue(), ^{
				aResultHandler(cachedData);
			});
			
			return;
		}
		
		@autoreleasepool {
			LoggerDataRead	*readOperation = \
				[[[LoggerDataRead alloc]
				  initWithBasepath:[self basepath]
				  filePath:aPath
				  callback_queue:[self dataEntryQueue]
				  callback:^(LoggerDataOperation *dataOperation, int error, NSData *data) {
					  MTLogInfo(@"[READ] Cache NOT Found %@ success %@ error %d",aPath,(!error?@"YES":@"NO"),error);
						if(error == 0)
						{
						 // handle success
						 aResultHandler(data);
						}
						else
						{
						 // handle error here
						}
					 
					 [self _deoperationQueue:dataOperation];
				 }] autorelease];

			[self _enoperationQueue:readOperation];
		}
	});
}

-(void)deleteWholePath:(NSString *)aPath
{
	if(IS_NULL_STRING(aPath))
		return;

	dispatch_async(_dataEntryQueue, ^{
		@autoreleasepool {
			LoggerDataDelete *deleteOperation = \
				[[[LoggerDataDelete alloc]
				  initWithBasepath:[self basepath]
				  filePath:aPath
				  callback_queue:[self dataEntryQueue]
				  callback:^(LoggerDataOperation *dataOperation, int error, NSData *data) {
					  MTLogInfo(@"%@ success %@ error %d",aPath,(!error?@"YES":@"NO"),error);
					 if(error == 0)
					 {
						 // handle success
					 }
					 else
					 {
						 // handle error here
					 }

					 [self _deoperationQueue:dataOperation];

				 }] autorelease];

			[self _enoperationQueue:deleteOperation];
		}
	});
}


//------------------------------------------------------------------------------
#pragma mark - Dequeue/Enqueue operations
//------------------------------------------------------------------------------
-(void)_enoperationQueue:(LoggerDataOperation *)anOperation
{	

	dispatch_async([self operationQueue], ^{
		
		if([anOperation isMemberOfClass:[LoggerDataWrite class]] ||
		   [anOperation isMemberOfClass:[LoggerDataDelete class]])
		{
			if([[self writeOperationSlot] count] < [self cpuCount])
			{
				[[self writeOperationSlot] addObject:anOperation];
				[anOperation executeOnQueue:[self dispatcherQueue]];
				MTLogInfo(@"[WRITE] en-slot<%d>\n(%@)"
						  ,[[self writeOperationSlot] count]
						  ,[anOperation path]);
			}
			else
			{
				[[self writeOperationReserve] addObject:anOperation];

				MTLogInfo(@"WRITE Enqueue (%d)",[[self writeOperationReserve] count]);
			}
			return;
		}

		if([anOperation isMemberOfClass:[LoggerDataRead class]])
		{

			if([[self readOperationSlot] count] < [self cpuCount])
			{
				[[self readOperationSlot] addObject:anOperation];
				
				[anOperation executeOnQueue:[self dispatcherQueue]];
				MTLogInfo(@"[READ] en-slot<%d>\n(%@)"
						  ,[[self readOperationSlot] count]
						  ,[anOperation path]);
			}
			else
			{
				[[self readOperationReserve] addObject:anOperation];
				MTLogInfo(@"READ Enqueue (%d)",[[self readOperationReserve] count]);
			}
			return;
		}
	});
}

-(void)_deoperationQueue:(LoggerDataOperation *)anOperation
{

	dispatch_async([self operationQueue], ^{
		
		if([anOperation isMemberOfClass:[LoggerDataWrite class]] ||
		   [anOperation isMemberOfClass:[LoggerDataDelete class]])
		{
			MTLogInfo(@"anOperation %@\nSlot # %d\nReserve # %d"
					  ,[anOperation description]
					  ,[[self writeOperationSlot] count]
					  ,[[self writeOperationReserve] count]);

			[[self writeOperationSlot] removeObject:anOperation];
			
			NSUInteger numInstructionWrite = \
				[[self writeOperationReserve] count];

			// when we have reserved instructions
			if(0 < numInstructionWrite)
			{
				// dequeue in FIFO order
				LoggerDataOperation *dataOp = \
					[[self writeOperationReserve] objectAtIndex:0];

				[[self writeOperationSlot] addObject:dataOp];
				[[self writeOperationReserve] removeObjectAtIndex:0];

				
				[dataOp executeOnQueue:[self dispatcherQueue]];
			}
			return;
		}

		if([anOperation isMemberOfClass:[LoggerDataRead class]])
		{

			MTLogInfo(@"anOperation %@\nSlot # %d\nReserve # %d"
					  ,[anOperation description]
					  ,[[self readOperationSlot]  count]
					  ,[[self readOperationReserve] count]);

			[[self readOperationSlot] removeObject:anOperation];

			NSUInteger numInstructionRead = \
				[[self readOperationReserve] count];
			
			if(0 < numInstructionRead)
			{	
				LoggerDataOperation *dataOp = \
					[[self readOperationReserve] objectAtIndex:0];
				
				[[self readOperationSlot] addObject:dataOp];
				[[self readOperationReserve] removeObjectAtIndex:0];

				[dataOp executeOnQueue:[self dispatcherQueue]];
				
			}
			return;
		}
	});
}

@end
