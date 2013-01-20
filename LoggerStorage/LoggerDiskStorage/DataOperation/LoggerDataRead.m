//
//  LoggerDataRead.m
//
//
//  Created by Almighty Kim on 12/23/12.
//  Copyright (c) 2012 Colorful Glue. All rights reserved.
//

#import "LoggerDataRead.h"

@implementation LoggerDataRead
-(operation_t)data_operation
{
	operation_t read_data = \
	^{
		int fd = open([[self path] UTF8String],O_RDONLY);
		
		dispatch_io_t channel_data_read = \
			dispatch_io_create(DISPATCH_IO_RANDOM
							   ,fd
							   ,[self queue_io_handler]
							   ,^(int error) {
								   close(fd);
							   });
		
		if(channel_data_read == NULL)
		{
			close(fd);
			dispatch_async([self queue_callback],^{
				self.callback(self,EIO,nil);
			});
		}
		else
		{
			dispatch_io_set_low_water(channel_data_read, 1);
			dispatch_io_set_high_water(channel_data_read, SIZE_MAX);
			
			dispatch_io_read(channel_data_read
							 ,0
							 ,SIZE_MAX
							 ,[self queue_io_handler]
							 ,^(bool done, dispatch_data_t data, int error) {
								 if(done)
								 {
									 if(!error)
									 {
										 const void *buffer = NULL;
										 size_t size = 0;
										 dispatch_data_t new_data_file __attribute__((unused)) = nil;
										 __block NSData *dataRead = nil;
										 
										 new_data_file = \
											 dispatch_data_create_map(data, &buffer, &size);
										 
										 //NSData is thread safe
										 dataRead = \
											 [[NSData alloc]
											  initWithBytesNoCopy:(void *)(buffer)
											  length:size
											  freeWhenDone:YES];

										 dispatch_async([self queue_callback],^{
											 self.callback(self,error,dataRead);
										 });

										 [dataRead release];
									 }
									 else
									 {
										 dispatch_async([self queue_callback],^{
											 self.callback(self,error,nil);
										 });
									 }
								 }
							 });
			dispatch_io_close(channel_data_read, 0);
			dispatch_release(channel_data_read);
		}
	};

	return [read_data copy];
}

@end
