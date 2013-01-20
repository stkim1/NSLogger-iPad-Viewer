//
//  LoggerDataStorage.m
//  LoggerStorage
//
//  Created by Almighty Kim on 12/16/12.
//  Copyright (c) 2012 Colorful Glue. All rights reserved.
//

#import "LoggerDataStorage.h"
#import "NullStringChecker.h"
#import "LoggerDataWrite.h"
#import "LoggerDataRead.h"
#import "LoggerDataDelete.h"
#import "LoggerDataEntry.h"

#define SHOW_LOG

typedef __block LoggerDataStorage* blockself_t;

@interface LoggerDataStorage()
@property (nonatomic, readonly) dispatch_queue_t		queueDataManager;
@property (nonatomic, readonly) dispatch_queue_t		queueOperation;
@property (nonatomic, readonly) dispatch_queue_t		queueDispatcher;

@property (nonatomic, readonly) NSMutableDictionary		*dataCache;
@property (nonatomic, readonly) NSMutableArray			*arrayWriteOperationReserve;
@property (nonatomic, readonly) NSMutableArray			*arrayReadOperationReserve;
@property (nonatomic, readonly) NSMutableArray			*slotReadOperation;
@property (nonatomic, readonly) NSMutableArray			*slotWriteOperation;

@property (nonatomic, retain)	NSString				*basepath;
//------------------------------------------------------------------------------
-(void)_enqueueOperation:(LoggerDataOperation *)anOperation;
-(void)_dequeueOperation:(LoggerDataOperation *)anOperation;
@end

@implementation LoggerDataStorage
{
	// this queue will handle instruction dependency issue,
	// enqueue instruction to instruction queue, and callback to UI-
	dispatch_queue_t		_queueDataManager;
	
	// this queue manages # of concurrent instructions,
	// and instruction queue
	dispatch_queue_t		_queueOperation;

	// this queue will concurrently dispatch actual instructions
	dispatch_queue_t		_queueDispatcher;

	// this is the cache pool that contains binary data
	NSMutableDictionary		*_dataCache;
	
	// read instruction reservation
	NSMutableArray			*_arrayWriteOperationReserve;
	
	// write instruction reservation (write/delete)
	NSMutableArray			*_arrayReadOperationReserve;

	// since we're to operation within instruction queue,
	// we don't want this to be volatile, which would consume more CPU cycles
	// we want this to be non-volatile, confined in a specific queue,
	// and runs blazing fast.
	NSMutableArray			*_slotReadOperation;
	NSMutableArray			*_slotWriteOperation;
	
	// a path where directory operation must based on
	NSString				*_basepath;
	
	int						_num_cpus;
}
@synthesize queueDataManager = _queueDataManager;
@synthesize queueOperation = _queueOperation;
@synthesize queueDispatcher = _queueDispatcher;
@synthesize slotReadOperation = _slotReadOperation;
@synthesize slotWriteOperation = _slotWriteOperation;

@synthesize dataCache = _dataCache;
@synthesize arrayWriteOperationReserve = _arrayWriteOperationReserve;
@synthesize arrayReadOperationReserve = _arrayReadOperationReserve;
@synthesize basepath = _basepath;

-(id)init
{
	self = [super init];
	if(self != nil)
	{
		// manages instruction dependency, create instruction, take
		// read/write/delete/purge command from other components
		_queueDataManager =\
			dispatch_queue_create("com.colorfulglue.loggerdatastorage.queuedatamanager"
								  ,DISPATCH_QUEUE_SERIAL);
		
		// read/write/delete/purge instruction handling queue
		_queueOperation = \
			dispatch_queue_create("com.colorfulglue.loggerdatastorage.queueinstruction"
								  ,DISPATCH_QUEUE_SERIAL);

		// process instruction
		_queueDispatcher = \
			dispatch_queue_create("com.colorfulglue.loggerdatastorage.queuedispatcher"
								  ,DISPATCH_QUEUE_CONCURRENT);

		
		dispatch_sync(_queueDataManager, ^{
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
		
		
		int cpuCount = [[NSProcessInfo processInfo] processorCount];
		
		dispatch_sync(_queueOperation, ^{
			_arrayWriteOperationReserve =\
				[[NSMutableArray alloc] initWithCapacity:4];
			
			_arrayReadOperationReserve =\
				[[NSMutableArray alloc] initWithCapacity:4];
			
			_slotReadOperation =\
				[[NSMutableArray alloc] initWithCapacity:cpuCount];
			
			_slotWriteOperation = \
				[[NSMutableArray alloc] initWithCapacity:cpuCount];

			_num_cpus = cpuCount;
		});
		
		
	}
	return self;
}

-(void)dealloc
{
	// need to dealloc arrays
	dispatch_sync(_queueDataManager, ^{
		[_dataCache removeAllObjects],[_dataCache release],_dataCache = nil;
		[_basepath release],_basepath = nil;
	});
	
	dispatch_sync(_queueOperation, ^{
		[_arrayReadOperationReserve removeAllObjects];
		[_arrayReadOperationReserve release];
		_arrayReadOperationReserve = nil;
		
		[_arrayWriteOperationReserve removeAllObjects];
		[_arrayWriteOperationReserve release];
		_arrayWriteOperationReserve = nil;
		
		[_slotReadOperation removeAllObjects];
		[_slotReadOperation release];
		_slotReadOperation = nil;
		
		[_slotWriteOperation removeAllObjects];
		[_slotWriteOperation release];
		_slotWriteOperation = nil;
	});
	
	dispatch_release(_queueDataManager);
	dispatch_release(_queueDispatcher);
    dispatch_release(_queueOperation);
	[super dealloc];
}


-(void)writeData:(NSData *)aData toPath:(NSString *)aFilepath
{		
	if(IS_NULL_STRING(aFilepath))
		return;

	if(aData == nil || ![aData length])
		return;

	dispatch_async(_queueDataManager, ^{
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
				  callback_queue:[self queueDataManager]
				  callback:^(LoggerDataOperation *dataOperation, int error, NSData *data) {
#ifdef SHOW_LOG
					 LogMessage(@"DataManager Write"
								,3
								,@"%@ success %@ error %d"
								,aFilepath
								,(!error?@"YES":@"NO"),error);
#endif
						if(error == 0)
						{
						// handle success
						}
						else
						{
						// handle error here
						}

					  [self _dequeueOperation:dataOperation];
					  [[entry operationQueue] removeObject:dataOperation];
				 }];

			[[entry operationQueue] addObject:writeOperation];
			
			
			// set entry for filepath
			[[self dataCache] setObject:entry forKey:aFilepath];
			[self _enqueueOperation:writeOperation];

			[entry release],entry = nil;
			[writeOperation release], writeOperation = nil;
		}
	});
}

-(void)readDataFromPath:(NSString *)aPath forResult:(void (^)(NSData *aData))aResultHandler
{
	//__block __typeof__(self) blockSelf = self;
	blockself_t blockSelf = self;
	
	if(IS_NULL_STRING(aPath))
	{
		aResultHandler(nil);
		return;
	}

	dispatch_async(_queueDataManager, ^{
		
		LoggerDataEntry *entry = [[self dataCache] objectForKey:aPath];
		
		if(entry != nil && [entry data] != nil)
		{
			NSData *cachedData = [entry data];

#ifdef SHOW_LOG
			LogMessage(@"DataManager Read"
					   ,3
					   ,@"[READ] Cache Found %@ success YES"
					   ,aPath);
#endif
			dispatch_async(dispatch_get_main_queue(), ^{
				aResultHandler(cachedData);
			});
			
			return;
		}
		
		@autoreleasepool {
			LoggerDataRead	*readOperation = \
				[[[LoggerDataRead alloc]
				  initWithBasepath:blockSelf->_basepath
				  filePath:aPath
				  callback_queue:blockSelf->_queueDataManager
				  callback:^(LoggerDataOperation *dataOperation, int error, NSData *data) {
#ifdef SHOW_LOG
					 LogMessage(@"DataManager Read"
								,3
								,@"[READ] Cache NOT Found %@ success %@ error %d"
								,aPath
								,(!error?@"YES":@"NO"),error);
#endif
					 if(error == 0)
					 {
						 // handle success
						 aResultHandler(data);
					 }
					 else
					 {
						 // handle error here
					 }
					 
					 [blockSelf
					  _dequeueOperation:dataOperation];
				 }] autorelease];

			[blockSelf
			 _enqueueOperation:readOperation];
		}
	});
}

-(void)deleteWholePath:(NSString *)aPath
{
	blockself_t blockSelf = self;
	
	if(IS_NULL_STRING(aPath))
		return;

	dispatch_async(_queueDataManager, ^{
		@autoreleasepool {
			LoggerDataDelete *deleteOperation = \
				[[[LoggerDataDelete alloc]
				  initWithBasepath:blockSelf->_basepath
				  filePath:aPath
				  callback_queue:blockSelf->_queueDataManager
				  callback:^(LoggerDataOperation *dataOperation, int error, NSData *data) {
#ifdef SHOW_LOG
					 LogMessage(@"DataManager Delete"
								,3
								,@"%@ success %@ error %d"
								,aPath
								,(!error?@"YES":@"NO"),error);
#endif
					 if(error == 0)
					 {
						 // handle success
					 }
					 else
					 {
						 // handle error here
					 }

					 [blockSelf
					  _dequeueOperation:dataOperation];

				 }] autorelease];
			
			[blockSelf
			 _enqueueOperation:deleteOperation];
		}
	});
}


//------------------------------------------------------------------------------
#pragma mark - Dequeue/Enqueue operations
//------------------------------------------------------------------------------
-(void)_enqueueOperation:(LoggerDataOperation *)anOperation
{	
	blockself_t blockSelf = self;
	
	dispatch_async(blockSelf->_queueOperation, ^{
		
		if([anOperation isMemberOfClass:[LoggerDataWrite class]] ||
		   [anOperation isMemberOfClass:[LoggerDataDelete class]])
		{
			if([blockSelf->_slotWriteOperation count] < blockSelf->_num_cpus)
			{
				[blockSelf->_slotWriteOperation addObject:anOperation];

				operation_t data_operation = [anOperation data_operation];
				dispatch_async(blockSelf->_queueDispatcher,data_operation);
				[data_operation release];

#ifdef SHOW_LOG
				LogMessage(@"Instruction"
						   ,3
						   ,@"[WRITE] en-slot<%d>\n(%@)"
						   ,[blockSelf->_slotWriteOperation count]
						   ,[anOperation path]);
#endif
			}
			else
			{
				[blockSelf->_arrayWriteOperationReserve
				 addObject:anOperation];
#ifdef SHOW_LOG
				LogMessage(@"Instruction"
						   ,3
						   ,@"WRITE Enqueue (%d)"
						   ,[blockSelf->_arrayWriteOperationReserve count]);
#endif
			}
			return;
		}

		if([anOperation isMemberOfClass:[LoggerDataRead class]])
		{

			if([blockSelf->_slotReadOperation count] < blockSelf->_num_cpus)
			{
				[blockSelf->_slotReadOperation addObject:anOperation];

				operation_t data_operation = [anOperation data_operation];
				dispatch_async(blockSelf->_queueDispatcher,data_operation);
				[data_operation release];
#ifdef SHOW_LOG
				LogMessage(@"Instruction"
						   ,3
						   ,@"[READ] en-slot<%d>\n(%@)"
						   ,[blockSelf->_slotReadOperation count]
						   ,[anOperation path]);
#endif
			}
			else
			{
				[blockSelf->_arrayReadOperationReserve addObject:anOperation];
#ifdef SHOW_LOG
				LogMessage(@"Instruction"
						   ,3
						   ,@"READ Enqueue (%d)"
						   ,[blockSelf->_arrayReadOperationReserve count]);
#endif
			}
			return;
		}
	});
}

-(void)_dequeueOperation:(LoggerDataOperation *)anOperation
{
	blockself_t blockSelf = self;
	
	dispatch_async(blockSelf->_queueOperation, ^{
		
		if([anOperation isMemberOfClass:[LoggerDataWrite class]] ||
		   [anOperation isMemberOfClass:[LoggerDataDelete class]])
		{
#ifdef SHOW_LOG
			LogMessage(@"Write QUEUE",
					   3,
					   @"anOperation %@\nSlot %@\nReserve %@"
					   ,[anOperation description]
					   ,[blockSelf->_slotWriteOperation description]
					   ,[blockSelf->_arrayWriteOperationReserve description]);
#endif
			[blockSelf->_slotWriteOperation removeObject:anOperation];
			
			NSUInteger numInstructionWrite = \
				[blockSelf->_arrayWriteOperationReserve count];

			// when we have reserved instructions
			if(0 < numInstructionWrite)
			{
				// dequeue in FIFO order
				LoggerDataOperation *instruction = \
					[blockSelf->_arrayWriteOperationReserve
					 objectAtIndex:0];

				[blockSelf->_slotWriteOperation addObject:instruction];
				[blockSelf->_arrayWriteOperationReserve removeObjectAtIndex:0];

				operation_t data_operation = [instruction data_operation];
				dispatch_async(blockSelf->_queueDispatcher,data_operation);
				[data_operation release];
#ifdef SHOW_LOG
				LogMessage(@"Instruction"
						   ,3
						   ,@"WRITE slot<%d> Dequeue (%d)"
						   ,[blockSelf->_slotWriteOperation count]
						   ,numInstructionWrite-1);
			}
			else
			{
				LogMessage(@"Instruction"
						   ,3
						   ,@"WRITE De-slot <%d> queue (%d)"
						   ,[blockSelf->_slotWriteOperation count]
						   ,numInstructionWrite);
#endif
			}
			return;
		}

		if([anOperation isMemberOfClass:[LoggerDataRead class]])
		{
#ifdef SHOW_LOG
			LogMessage(@"Read QUEUE"
					   ,3
					   ,@"anOperation %@\nSlot %@\nReserve %@"
					   ,[anOperation description]
					   ,[blockSelf->_slotReadOperation description]
					   ,[blockSelf->_arrayReadOperationReserve description]);
#endif
			[blockSelf->_slotReadOperation removeObject:anOperation];
			
			NSUInteger numInstructionRead = \
				[blockSelf->_arrayReadOperationReserve count];
			
			if(0 < numInstructionRead)
			{	
				LoggerDataOperation *instruction = \
					[blockSelf->_arrayReadOperationReserve
					 objectAtIndex:0];
				
				[blockSelf->_slotReadOperation addObject:instruction];
				[blockSelf->_arrayReadOperationReserve removeObjectAtIndex:0];

				operation_t data_operation = [instruction data_operation];
				dispatch_async(blockSelf->_queueDispatcher,data_operation);
				[data_operation release];
				
#ifdef SHOW_LOG
				LogMessage(@"Instruction"
						   ,3
						   ,@"READ slot<%d> Dequeue (%d)"
						   ,[blockSelf->_slotReadOperation count]
						   ,numInstructionRead-1);
			}
			else
			{
				LogMessage(@"Instruction"
						   ,3
						   ,@"READ De-slot <%d> queue (%d)"
						   ,[blockSelf->_slotReadOperation count]
						   ,numInstructionRead);
#endif
			}
			return;
		}
	});
}

@end
