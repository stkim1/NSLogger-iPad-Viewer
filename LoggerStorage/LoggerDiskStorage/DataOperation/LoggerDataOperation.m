/*
 *
 * BSD license follows (http://www.opensource.org/licenses/bsd-license.php)
 *
 * Copyright (c) 2012-2013 Sung-Taek, Kim <stkim1@colorfulglue.com> All Rights Reserved.
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
