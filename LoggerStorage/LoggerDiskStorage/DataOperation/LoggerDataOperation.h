//
//  LoggerDataOperation.h
//  LoggerStorage
//
//  Created by Almighty Kim on 12/23/12.
//  Copyright (c) 2012 Colorful Glue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NullStringChecker.h"

@class LoggerDataOperation;

typedef void (^callback_t)(LoggerDataOperation *dataOperation, int error, NSData *data);
typedef void (^operation_t)(void);

#define ENOBASEPATH			0xBABA		/* no base directory presented */
#define ENOFILEPATH			0xBABE		/* not proper file path */

@interface LoggerDataOperation : NSObject
{
	NSString						*_path;
	dispatch_queue_t				_queue_io_handler;
	dispatch_queue_t				_queue_callback;
	callback_t						_callback;
}
@property (nonatomic, readonly) NSString						*path;
@property (nonatomic, readonly) dispatch_queue_t			 	queue_io_handler;
@property (nonatomic, readonly) dispatch_queue_t			 	queue_callback;
@property (nonatomic, readonly) callback_t					 	callback;
-(id)initWithBasepath:(NSString *)aBasepath
			 filePath:(NSString *)aFilepath
	   callback_queue:(dispatch_queue_t)a_callback_queue
			 callback:(callback_t)a_callback_block;
-(operation_t)data_operation;
@end
