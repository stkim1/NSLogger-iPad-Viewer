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
