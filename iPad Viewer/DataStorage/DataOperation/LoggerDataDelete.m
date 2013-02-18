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


#import "LoggerDataDelete.h"
#include <fts.h>
#include <errno.h>

@implementation LoggerDataDelete
-(void)executeOnQueue:(dispatch_queue_t)aQueue
{
	dispatch_async(aQueue,^{
		// See man fts(3) for these.  Modify these to do what you want.
		// here, the combination options mean do not follow child dir,
		// no statistics report, no following symbolic link
		int fts_options =  FTS_PHYSICAL | FTS_NOCHDIR | FTS_XDEV ;
		
		// fts_open requires a null-terminated array of paths.
		const char * fts_paths[2] = {[[self path] UTF8String],NULL};
		
		errno = 0;
		FTS* ftsp = fts_open((char * const *)fts_paths, fts_options, NULL);
		if (ftsp == NULL)
		{
			int error_no = errno;
			dispatch_async([self queue_callback],^{
				self.callback(self,error_no,nil);
			});
		}

		FTSENT	*ftsPointer = NULL;
		while ((ftsPointer = fts_read(ftsp)) != NULL)
		{
			switch (ftsPointer->fts_info)
			{
				// regular file
				case FTS_F:
					remove(ftsPointer->fts_path);
					break;
				default:
					break;
			}
		}
		
		errno = 0;
		if(fts_close(ftsp) != 0)
		{
			int error_no = errno;
			dispatch_async([self queue_callback],^{
				self.callback(self,error_no,nil);
			});
		}

		errno = 0;
		if(rmdir([[self path] UTF8String]) != 0)
		{
			int error_no = errno;
			dispatch_async([self queue_callback],^{
				self.callback(self,error_no,nil);
			});
		}
		else
		{
			dispatch_async([self queue_callback],^{
				self.callback(self,0,nil);
			});
		}
	
	});
}
@end
