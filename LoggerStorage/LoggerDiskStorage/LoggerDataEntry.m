
//
//  LoggerDataEntry.m
//  LoggerStorage
//
//  Created by Almighty Kim on 1/8/13.
//  Copyright (c) 2013 Colorful Glue. All rights reserved.
//

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

void
_split_dir_only(char** p, const char *pf)
{
    char *slash = (char *)pf, *next;
    while ((next = strpbrk(slash + 1, "\\/"))) slash = next;
    if (pf != slash) slash++;
    *p = strndup(pf, slash - pf);
}


@end
