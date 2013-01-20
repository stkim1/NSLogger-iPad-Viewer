//
//  LoggerDataWrite.h
//  LoggerStorage
//
//  Created by Almighty Kim on 12/23/12.
//  Copyright (c) 2012 Colorful Glue. All rights reserved.
//

#import "LoggerDataOperation.h"

@interface LoggerDataWrite : LoggerDataOperation
// once you set the data, path, and callback,
// you can never change them in the lifetime of an instance
-(id)initWithData:(NSData *)aData
		 basepath:(NSString *)aBasepath
		 filePath:(NSString *)aFilepath
dirPartOfFilepath:(NSString *)aDirPartOfFilepath
   callback_queue:(dispatch_queue_t)a_callback_queue
		 callback:(callback_t)a_callback_block;
@end
