//
//  LoggerDataOperation.m
//  LoggerStorage
//
//  Created by Almighty Kim on 12/23/12.
//  Copyright (c) 2012 Colorful Glue. All rights reserved.
//

#import "LoggerDataOperation.h"

@interface LoggerDataOperation()
static void _split_dir_only(char**, const char*);
@end

@implementation LoggerDataOperation
@synthesize path = _path;
@synthesize callback = _callback;
@synthesize queue_io_handler = _queue_io_handler;
@synthesize queue_callback = _queue_callback;

-(id)initWithBasepath:(NSString *)aBasepath
			 filePath:(NSString *)aFilepath
	   callback_queue:(dispatch_queue_t)a_callback_queue
			 callback:(callback_t)a_callback_block
{
	self = [super init];
	if(self)
	{
		_path = [[NSString stringWithFormat:@"%@%@",aBasepath,aFilepath] retain];
		
		/*
		 If multiple subsystems of your application share a dispatch object,
		 each subsystem should call dispatch_retain to register its interest
		 in the object. The object is deallocated only when all subsystems
		 have released their interest in the dispatch source.
		 */
		_queue_callback = a_callback_queue;
		dispatch_retain(_queue_callback);
		
		_callback = [a_callback_block copy];

		_queue_io_handler =\
			dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND,0);
	}
	return self;
}

-(void)dealloc
{
//	NSLog(@"%@ dealloced",NSStringFromClass([self class]));
	
	[_path release],_path = nil;
	dispatch_release(_queue_callback),_queue_callback = NULL;
	[_callback release], _callback = NULL;
	_queue_io_handler = NULL;
	[super dealloc];
}

-(operation_t)data_operation
{
	return NULL;
}

@end
