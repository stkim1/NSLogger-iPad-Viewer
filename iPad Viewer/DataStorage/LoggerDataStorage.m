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


#import "LoggerFakeDelete.h"
#import "LoggerFakeRead.h"
#import "LoggerFakeWrite.h"


@interface LoggerDataStorage()
@property (nonatomic, readonly) dispatch_queue_t		lowPriorityOperationQueue;
@property (nonatomic, readonly) dispatch_queue_t		highPriorityOperationQueue;
@property (nonatomic, readonly) dispatch_queue_t		operationDispatcherQueue;

@property (nonatomic, readonly) NSMutableDictionary		*dataEntryCache;

@property (nonatomic, readonly) NSMutableArray			*operationPool;
@property (nonatomic, readonly) NSMutableArray			*writeOperationSlot;
@property (nonatomic, readonly) NSMutableArray			*readOperationSlot;

@property (nonatomic, retain)	NSString				*basepath;
@property (nonatomic, readonly) int						cpuCount;

-(void)_enqueueWriteOperationForData:(NSData *)aData toPath:(NSString *)aFilepath;
-(void)_dequeueOperation:(LoggerDataOperation *)anOperation;
@end

@implementation LoggerDataStorage
{
	// this queue will handle instruction dependency issue,
	// enqueue instruction to instruction queue, and callback to UI-
	dispatch_queue_t		_lowPriorityOperationQueue;
	
	// this queue manages # of concurrent instructions,
	// and instruction queue
	dispatch_queue_t		_highPriorityOperationQueue;

	// this queue will concurrently dispatch actual instructions
	dispatch_queue_t		_operationDispatcherQueue;

	// this is the cache pool that contains binary data
	NSMutableDictionary		*_dataEntryCache;
	
	// data operation queue
	NSMutableArray			*_operationPool;
	
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
@synthesize lowPriorityOperationQueue			= _lowPriorityOperationQueue;
@synthesize highPriorityOperationQueue			= _highPriorityOperationQueue;
@synthesize operationDispatcherQueue			= _operationDispatcherQueue;

@synthesize readOperationSlot					= _readOperationSlot;
@synthesize writeOperationSlot					= _writeOperationSlot;

@synthesize operationPool						= _operationPool;

@synthesize dataEntryCache						= _dataEntryCache;

@synthesize basepath							= _basepath;
@synthesize cpuCount							= _cpuCount;

SYNTHESIZE_SINGLETON_FOR_CLASS_WITH_ACCESSOR(LoggerDataStorage,sharedDataStorage);

-(id)init
{
	self = [super init];
	if(self != nil)
	{
		// manages instruction dependency, create instruction, take
		// read/write/delete/purge command from other components
		_lowPriorityOperationQueue =\
			dispatch_queue_create("com.colorfulglue.loggerdatastorage.datamanagerqueue"
								  ,DISPATCH_QUEUE_SERIAL);
		
		// read/write/delete/purge instruction handling queue
		_highPriorityOperationQueue = \
			dispatch_queue_create("com.colorfulglue.loggerdatastorage.operationqueue"
								  ,DISPATCH_QUEUE_SERIAL);

		// process instruction
		_operationDispatcherQueue = \
			dispatch_queue_create("com.colorfulglue.loggerdatastorage.dispatcherqueue"
								  ,DISPATCH_QUEUE_CONCURRENT);

		
		// low priority queue will target high priority
		dispatch_set_target_queue(_lowPriorityOperationQueue,_highPriorityOperationQueue);
		
		
		int cpus = [[NSProcessInfo processInfo] processorCount];
		
		dispatch_sync(_highPriorityOperationQueue, ^{
			NSArray *paths = \
				NSSearchPathForDirectoriesInDomains(NSDocumentDirectory
													,NSUserDomainMask, YES);
			NSString *path = \
				([paths count] > 0) ? [paths objectAtIndex:0] : nil;
			
			NSString *targetPath = \
				(path) ? [NSString stringWithFormat:@"%@/",path] : nil;
			
			_basepath = [targetPath retain];

			_dataEntryCache = \
				[[NSMutableDictionary alloc] initWithCapacity:0];
			
			
			// operation queue setup
			_cpuCount = cpus;

			_operationPool =\
				[[NSMutableArray alloc] initWithCapacity:_cpuCount * 2];
			
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
	dispatch_sync(_highPriorityOperationQueue, ^{
		[_dataEntryCache removeAllObjects],[_dataEntryCache release],_dataEntryCache = nil;
		[_basepath release],_basepath = nil;
		
		[_readOperationSlot removeAllObjects];
		[_readOperationSlot release];
		_readOperationSlot = nil;
		
		[_writeOperationSlot removeAllObjects];
		[_writeOperationSlot release];
		_writeOperationSlot = nil;
	});

	dispatch_release(_lowPriorityOperationQueue),_lowPriorityOperationQueue = NULL;
    dispatch_release(_highPriorityOperationQueue),_highPriorityOperationQueue = NULL;
	dispatch_release(_operationDispatcherQueue),_operationDispatcherQueue = NULL;

	[super dealloc];
}


-(void)writeData:(NSData *)aData toPath:(NSString *)aFilepath
{
	MTLogVerify(@"%s data # %d path %@",__PRETTY_FUNCTION__,[aData length],aFilepath);
	
	if(IS_NULL_STRING(aFilepath))
		return;

	if(aData == nil || ![aData length])
		return;

	dispatch_async([self highPriorityOperationQueue], ^{
		[self _enqueueWriteOperationForData:aData toPath:aFilepath];
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

	dispatch_async([self lowPriorityOperationQueue], ^{
		
		LoggerDataEntry *entry = [[self dataEntryCache] objectForKey:aPath];
		
		if(entry != nil && [entry data] != nil)
		{
			MTLogInfo(@"[READ] Cache Found %@ success YES",aPath);
			
			NSData *cachedData = [entry data];
			aResultHandler(cachedData);
			
			return;
		}

		// cannot find an entry from cache. find it from file system
		dispatch_async([self highPriorityOperationQueue], ^{
			[self _enqueueReadOperationForFile:aPath result:aResultHandler];
		});
		
	});
}

-(void)deleteWholePath:(NSString *)aPath
{
}


//------------------------------------------------------------------------------
#pragma mark - Dequeue/Enqueue operations
//------------------------------------------------------------------------------
-(void)_enqueueWriteOperationForData:(NSData *)aData
							  toPath:(NSString *)aFilepath
{
	assert(dispatch_get_current_queue() == [self highPriorityOperationQueue]);

	__block unsigned int dependencyCount = 0;
	
	LoggerDataEntry *dataEntry = \
		[[LoggerDataEntry alloc] initWithFilepath:aFilepath];
	[dataEntry setData:aData];

	// set cache entry for filepath
	[[self dataEntryCache] setObject:dataEntry forKey:aFilepath];
	
#ifdef CHECK_OPERATION_DEPENDENCY
	// check operation dependency
	if([[self operationPool] count])
	{
		[[self operationPool]
		 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			if([obj isKindOfClass:[LoggerDataDelete class]])
			{
			}
		 }];
		
	}
#endif

	LoggerFakeWrite	*writeOperation = \
		[[LoggerFakeWrite alloc]
		 initWithData:[dataEntry data]
		 basepath:[self basepath]
		 filePath:[dataEntry filepath]
		 dirPartOfFilepath:[dataEntry dirOfFilepath]
		 callback_queue:[self highPriorityOperationQueue]
		 callback:^(LoggerDataOperation *dataOperation, int error, NSData *data) {
			 MTLogInfo(@"%@ success %@ error %d",[dataEntry filepath],(!error?@"YES":@"NO"),error);
			 
			 // handle success
			 if(error == 0)
			 {
			 }
			 // handle error here
			 else
			 {
			 }

			 [[dataEntry dataOperations] removeObject:dataOperation];
			 [self _dequeueOperation:dataOperation];
			 
		 }];

	[writeOperation setDependencyCount:dependencyCount];

	// add this operation to dataOperation of anEntry
	[[dataEntry dataOperations] addObject:writeOperation];

	// add operation to pool
	[[self operationPool] addObject:writeOperation];
	
	// if there is no dependency and write op slot is available, execute this operation
	if(!dependencyCount && [[self writeOperationSlot] count] < [self cpuCount])
	{
		[[self writeOperationSlot] addObject:writeOperation];
		[writeOperation executeOnQueue:[self operationDispatcherQueue]];
		MTLogInfo(@"[WRITE] en-slot<%d>\n(%@)"
				  ,[[self writeOperationSlot] count]
				  ,[writeOperation path]);
	}

	[dataEntry release],dataEntry = nil;
	[writeOperation release],writeOperation = nil;
}


-(void)_enqueueReadOperationForFile:(NSString *)aFilepath
							 result:(void (^)(NSData *aData))aResultHandler
{
	assert(dispatch_get_current_queue() == [self highPriorityOperationQueue]);
	
	__block unsigned int dependencyCount = 0;
	
	LoggerDataEntry *dataEntry =
		[[LoggerDataEntry alloc] initWithFilepath:aFilepath];
	
	// set cache entry for filepath
	[[self dataEntryCache] setObject:dataEntry forKey:aFilepath];
	
#ifdef CHECK_OPERATION_DEPENDENCY
	// check operation dependency
	if([[self operationPool] count])
	{
		[[self operationPool]
		 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			 if([obj isKindOfClass:[LoggerDataDelete class]])
			 {
			 }
		 }];
		
	}
#endif
	
	LoggerFakeRead	*readOperation = \
		[[LoggerFakeRead alloc]
		  initWithBasepath:[self basepath]
		  filePath:[dataEntry filepath]
		  callback_queue:[self highPriorityOperationQueue]
		  callback:^(LoggerDataOperation *dataOperation, int error, NSData *data) {
			  MTLogInfo(@"[READ] Cache NOT Found %@ success %@ error %d",aFilepath,(!error?@"YES":@"NO"),error);
			  if(error == 0)
			  {
				  [dataEntry setData:data];
				  // handle success
				  aResultHandler(data);
				  [[dataEntry dataOperations] removeObject:dataOperation];
			  }
			  else
			  {
				  // if read operation fails, remove datacache
				  [[self dataEntryCache] removeObjectForKey:aFilepath];
			  }
			  
			  [self _dequeueOperation:dataOperation];

		  }];
	
	[readOperation setDependencyCount:dependencyCount];
	
	// add this operation to dataOperation of anEntry
	[[dataEntry dataOperations] addObject:readOperation];
	
	// add operation to pool
	[[self operationPool] addObject:readOperation];
	
	// if there is no dependency and write op slot is available, execute this operation
	if(!dependencyCount && [[self readOperationSlot] count] < [self cpuCount])
	{
		[[self readOperationSlot] addObject:readOperation];
		[readOperation executeOnQueue:[self operationDispatcherQueue]];
		MTLogInfo(@"[READ] en-slot<%d>\n(%@)"
				  ,[[self readOperationSlot] count]
				  ,[readOperation path]);
	}
	
	[dataEntry release],dataEntry = nil;
	[readOperation release],readOperation = nil;
}






//------------------------------------------------------------------------------
#pragma mark - Dequeue operations
//------------------------------------------------------------------------------
-(void)_dequeueOperation:(LoggerDataOperation *)anOperation
{
	dispatch_async([self highPriorityOperationQueue], ^{

		// first retain the operation for a while
		[anOperation retain];
		
		// remove the operation from exec slot
		if([anOperation isKindOfClass:[LoggerDataWrite class]] ||
		   [anOperation isKindOfClass:[LoggerDataDelete class]])
		{
			[[self writeOperationSlot] removeObject:anOperation];
		}
		else
		{
			[[self readOperationSlot] removeObject:anOperation];
		}
		
		// remove from pool
		[[self operationPool] removeObject:anOperation];
		
		// search next operation & check dependent operations
		__block LoggerDataOperation *nextOperation = nil;
		
		if([[self operationPool] count])
		{
			[[self operationPool]
			 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

				 LoggerDataOperation *dataOp = (LoggerDataOperation *)obj;
				 
				 // check operation dependency, remove dependency count by one
#ifdef CHECK_OPERATION_DEPENDENCY
#endif
				/* condition for finding the next operation is...
				 * 1) next target is not found
				 * 2) operation's dependency is 0
				 * 3) an operatin is not contained in read slot
				 * 4) an operatin is not contained in write slot
				 */

				if(nextOperation == nil && !dataOp.dependencyCount)
				{
			
				   if(![[self readOperationSlot] containsObject:obj] &&
					  ![[self writeOperationSlot] containsObject:obj])
					{
						MTLogInfo(@"nextOperation found");
						nextOperation = [dataOp retain];
					}
				}
			 }];
		}

		// now operation is done with its job. release it
		[anOperation release];
		
		// if there is no dependency and read|write op slot is available,
		// execute this operation
		if(nextOperation != nil)
		{
			if([nextOperation isKindOfClass:[LoggerDataWrite class]] ||
			   [nextOperation isKindOfClass:[LoggerDataDelete class]])
			{

				if([[self writeOperationSlot] count] < [self cpuCount])
				{
					[[self writeOperationSlot] addObject:nextOperation];
					[nextOperation executeOnQueue:[self operationDispatcherQueue]];
					MTLogInfo(@"[WRITE] en-slot<%d>\n(%@)"
							  ,[[self writeOperationSlot] count]
							  ,[nextOperation path]);
				}
				
			}
			
			
			if([nextOperation isKindOfClass:[LoggerDataRead class]])
			{
				if([[self readOperationSlot] count] < [self cpuCount])
				{
					[[self readOperationSlot] addObject:nextOperation];
					[nextOperation executeOnQueue:[self operationDispatcherQueue]];
					MTLogInfo(@"[READ] en-slot<%d>\n(%@)"
							  ,[[self readOperationSlot] count]
							  ,[nextOperation path]);
				}
			}

			[nextOperation release],nextOperation = nil;
		}
	});
}

@end
