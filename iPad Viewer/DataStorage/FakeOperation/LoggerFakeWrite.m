//
//  LoggerFakeWrite.m
//  ipadnslogger
//
//  Created by Almighty Kim on 2/24/13.
//  Copyright (c) 2013 Colorful Glue. All rights reserved.
//

#import "LoggerFakeWrite.h"

@implementation LoggerFakeWrite
-(void)executeOnQueue:(dispatch_queue_t)aQueue
{
	//dispatch_time_t time = dispatch_walltime(NULL,1000000);
	double delayInSeconds = 2.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, aQueue,^{
		dispatch_async ([self queue_callback],^{
			MTLogDebug(@"LoggerFakeWrite executeOnQueue Done");
			self.callback(self,0,nil);
		});
	});
}
@end
