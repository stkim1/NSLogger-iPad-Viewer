//
//  Macro.h
//  
//  Created by Almighty Kim on 8/23/09.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

// This macro defines 1) log printout, 2)Assertion, 3)dealloc check,
// and 4) delloac helper.


#ifdef DEBUG
	#define MTLog(args...)			\
		NSLog(@"%@",[NSString stringWithFormat:args])
	#define MTAssert(cond,desc...)	\
		NSAssert(cond, @"%@", [NSString stringWithFormat: desc])
	#define MTDealloc(__POINTER) \
		do{ MTLog(@"%@ dealloc",self); [super dealloc]; } while(0)
#else
	#define MTLog(args...)
	#define MTAssert(cond,desc...)
	#define MTDealloc(__POINTER) \
		do { [super dealloc]; } while(0)
#endif

#define LoggerCheckDelegate(__POINTER,__PROTOCOL,__SELECTOR) \
		((__POINTER != nil) &&\
		[(id)__POINTER conformsToProtocol:__PROTOCOL] &&\
		[(id)__POINTER respondsToSelector:__SELECTOR])