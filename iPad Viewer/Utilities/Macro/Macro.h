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

/*
// This macro defines
	1) log printout,
	2) Assertion, 3)dealloc check,
	3) delloac helper.
	4) delegate check
*/

#ifdef DEBUG
	#define MTLogVerify(args...) NSLog(@"%@",[NSString stringWithFormat:args])
	#define MTLogInfo(args...)   NSLog(@"%@",[NSString stringWithFormat:args])
	#define MTLogDebug(args...)  NSLog(@"%@",[NSString stringWithFormat:args])
	#define MTLogError(args...)  NSLog(@"%@",[NSString stringWithFormat:args])
	#define MTLogAssert(args...) NSLog(@"%@",[NSString stringWithFormat:args])

	#define MTLog(args...)			\
		NSLog(@"%@",[NSString stringWithFormat:args])
	#define MTAssert(cond,desc...)	\
		NSAssert(cond, @"%@", [NSString stringWithFormat: desc])
	#define MTDealloc(__POINTER) \
		do{ MTLog(@"%@ dealloc",self); [super dealloc]; } while(0)
#else
	#define MTLogVerify(args...)
	#define MTLogInfo(args...)
	#define MTLogDebug(args...)
	#define MTLogError(args...)
	#define MTLogAssert(args...)
	#define MTLog(args...)
	#define MTAssert(cond,desc...)
	#define MTDealloc(__POINTER) \
		do { [super dealloc]; } while(0)
#endif

#define LoggerCheckDelegate(__POINTER,__PROTOCOL,__SELECTOR) \
		((__POINTER != nil) &&\
		[(id)__POINTER conformsToProtocol:__PROTOCOL] &&\
		[(id)__POINTER respondsToSelector:__SELECTOR])