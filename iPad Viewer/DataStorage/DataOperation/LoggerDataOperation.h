/*
 *
 * BSD license follows (http://www.opensource.org/licenses/bsd-license.php)
 *
 * Copyright (c) 2012-2013 Sung-Taek, Kim <stkim1@colorfulglue.com> All Rights
 * Reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * Redistributions of  source code  must retain  the above  copyright notice,
 * this list of  conditions and the following  disclaimer. Redistributions in
 * binary  form must  reproduce  the  above copyright  notice,  this list  of
 * conditions and the following disclaimer  in the documentation and/or other
 * materials  provided with  the distribution.  Neither the  name of Sung-Tae
 * k Kim nor the names of its contributors may be used to endorse or promote
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


#import <Foundation/Foundation.h>
#import "NullStringCheck.h"

@class LoggerDataOperation;

typedef void (^callback_t)(LoggerDataOperation *dataOperation, int error, NSData *data);

#define ENOBASEPATH			0xBABA		/* no base directory presented */
#define ENOFILEPATH			0xBABE		/* not proper file path */

@interface LoggerDataOperation : NSObject
{
	NSString						*_basepath;
	NSString						*_filepath;
	NSString						*_dirPartOfFilepath;
	NSString						*_absTargetFilePath;

	dispatch_queue_t				_queue_io_handler;
	dispatch_queue_t				_queue_callback;
	callback_t						_callback;
	
	BOOL							_executing;
	unsigned int					_dependencyCount;
}
@property (nonatomic, readonly) NSString						*basepath;
@property (nonatomic, readonly) NSString						*filepath;
@property (nonatomic, readonly) NSString						*dirPartOfFilepath; // directory part of path
@property (nonatomic, readonly) NSString						*absTargetFilePath; // target file path
@property (nonatomic, readonly) dispatch_queue_t			 	queue_io_handler;	// io handling queue
@property (nonatomic, readonly) dispatch_queue_t			 	queue_callback;		// callback queue
@property (nonatomic, readonly) callback_t					 	callback;			// callback
@property (nonatomic, getter=isExecuting, readwrite) BOOL		executing;			// execution indicator
@property (nonatomic, readwrite) unsigned int					dependencyCount;	// # operations this op is dependent

-(id)initWithBasepath:(NSString *)aBasepath
			 filePath:(NSString *)aFilepath
		dirOfFilepath:(NSString *)aDirOfFilepath
	   callback_queue:(dispatch_queue_t)a_callback_queue
			 callback:(callback_t)a_callback_block;
-(void)executeOnQueue:(dispatch_queue_t)aQueue;
@end
