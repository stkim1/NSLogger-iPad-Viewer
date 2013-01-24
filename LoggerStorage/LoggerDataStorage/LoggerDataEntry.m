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


#import "LoggerDataEntry.h"
#import "NullStringChecker.h"

@interface LoggerDataEntry()
static void _split_dir_only(char**, const char*);
@end

@implementation LoggerDataEntry
{
	NSString						*_filepath;
	char							*_fpath_dir_part;
	NSString						*_dirOfFilepath;
	NSMutableArray					*_operationQueue;

	NSData							*_data;
}
@synthesize filepath = _filepath;
@synthesize dirOfFilepath = _dirOfFilepath;
@synthesize operationQueue = _operationQueue;
@synthesize data = _data;

-(id)initWithFilepath:(NSString *)aFilepath
{
	self = [super init];

	if(self)
	{
		// should never pass a null string
		assert(!IS_NULL_STRING(aFilepath));

		_filepath = [aFilepath retain];
		_operationQueue = [[NSMutableArray alloc] initWithCapacity:0];
		
		// split diretory part from file path
		_fpath_dir_part = NULL;
		_split_dir_only(&_fpath_dir_part,[aFilepath UTF8String]);

NSLog(@"fpath_path %s(%p)[%zd]",_fpath_dir_part,_fpath_dir_part,strlen(_fpath_dir_part));
		
		// this is an error. should never happpen
		assert(_fpath_dir_part != NULL);
		
		// in case when you want to write a file at basepath...
		if(strlen(_fpath_dir_part) == 0)
		{
			//clean up and proceed
			free(_fpath_dir_part),_fpath_dir_part = NULL;
			_dirOfFilepath = nil;
		}
		// we have proper dir part of filepath now.
		else
		{
			_dirOfFilepath = \
				[[NSString alloc]
				 initWithBytesNoCopy:_fpath_dir_part
				 length:strlen(_fpath_dir_part)
				 encoding:NSASCIIStringEncoding
				 freeWhenDone:NO];
		}

	}
	return self;
}


-(void)dealloc
{	
	[_filepath release],_filepath = nil;

	if(_dirOfFilepath != nil)
	{
		[_dirOfFilepath release],_dirOfFilepath = nil;
	}

	if(_fpath_dir_part != NULL)
	{
		free(_fpath_dir_part),_fpath_dir_part = NULL;
	}

	[_operationQueue removeAllObjects];
	[_operationQueue release],_operationQueue = nil;

	self.data = nil;

	[super dealloc];
}

// This function come from ephemient of stackoverflow
//http://stackoverflow.com/questions/1575278/function-to-split-a-filepath-into-path-and-file/1575314#1575314
void
_split_dir_only(char** p, const char *pf)
{
    char *slash = (char *)pf, *next;
    while ((next = strpbrk(slash + 1, "\\/"))) slash = next;
    if (pf != slash) slash++;
    *p = strndup(pf, slash - pf);
}

@end
