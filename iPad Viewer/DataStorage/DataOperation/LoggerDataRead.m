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
-(void)executeOnQueue:(dispatch_queue_t)aQueue
{
	dispatch_async(aQueue,^{
		int fd = open([[self absTargetFilePath] UTF8String],O_RDONLY);
		
		MTLogVerify(@"%s %@",__PRETTY_FUNCTION__,[self absTargetFilePath]);

		
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
			__block dispatch_data_t lead = NULL;
			dispatch_io_read(channel_data_read
							 ,0
							 ,SIZE_MAX
							 ,[self queue_io_handler]
							 ,^(bool done, dispatch_data_t data, int error) {
								 if(lead == NULL)
								 {
									 lead = data;
									 dispatch_retain(lead);
								 }
								 else
								 {
									 dispatch_data_t concat = dispatch_data_create_concat(lead,data);
									 dispatch_release(lead);
									 lead = concat;
								 }
								 
								 if(!done) return;
								 
								 if(!error)
								 {
									 const void *buffer = NULL;
									 size_t size = 0;
									 
									 dispatch_data_t new_data_file =\
									 dispatch_data_create_map(lead, &buffer, &size);
									 
									 MTLog(@"======= data read size %zd ======= ",size);
									 //NSData is thread safe
									 NSData *dataRead = \
										 [[NSData alloc]
										  initWithBytesNoCopy:(void *)(buffer)
										  length:size
										  freeWhenDone:YES];
									 
									 dispatch_async([self queue_callback],^{
										 self.callback(self,error,dataRead);
									 });
									 
									 [dataRead release];
									 dispatch_release(new_data_file);
								 }
								 else
								 {
									 dispatch_async([self queue_callback],^{
										 self.callback(self,error,nil);
									 });
								 }
								 
								 if(lead != NULL){
									 dispatch_release(lead);
								 }
							 });
			dispatch_io_close(channel_data_read, 0);
			dispatch_release(channel_data_read);
		}
	});
}

@end
