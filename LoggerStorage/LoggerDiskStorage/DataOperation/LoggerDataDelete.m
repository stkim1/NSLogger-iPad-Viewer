//
//  LoggerDataDelete.m
//  LoggerStorage
//
//  Created by Almighty Kim on 12/29/12.
//  Copyright (c) 2012 Colorful Glue. All rights reserved.
//

#import "LoggerDataDelete.h"
#include <fts.h>
#include <errno.h>

@implementation LoggerDataDelete
-(operation_t)data_operation
{
	operation_t delete_data = \
	^{
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
		
	};

	return [delete_data copy];
}
@end
