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


#import "LoggerMessageData.h"
#import "LoggerDataStorage.h"
#import "LoggerMessageCell.h"

@interface LoggerMessageData()
-(LoggerMessageCell *)messageCell;
-(void)setMessageCell:(LoggerMessageCell *)aCell;
@end

@implementation LoggerMessageData
{
	LoggerMessageCell		*_targetCell;
	BOOL					_isReadImageTriggered;
}
@dynamic clientHash;
@dynamic contentsType;
@dynamic dataFilepath;
@dynamic filename;
@dynamic functionName;
@dynamic imageSize;
@dynamic landscapeHeight;
@dynamic level;
@dynamic lineNumber;
@dynamic messageText;
@dynamic messageType;
@dynamic portraitHeight;
@dynamic runCount;
@dynamic sequence;
@dynamic tag;
@dynamic textRepresentation;
@dynamic threadID;
@dynamic timestamp;
@dynamic type;

-(unsigned long)rawDataSize
{
	unsigned long size = 0;
	
	size += 4;// client hash
	size += 2;// contentsType
	size += [[self dataFilepath] length];
	size += [[self filename] length];
	size += [[self functionName] length];
	size += [[self imageSize] length];
	size += 4; // landscape height
	size += 4; // run count
	size += 4; // sequence
	size += 4; // tag
	size += [[self threadID] length];
	size += 8; // timestamp
	size += 2; // type;
	size += 4; // lineNumber
	size += [[self messageText] length];
	size += [[self messageType] length];
	size += [[self textRepresentation] length];
	
	return size;
	
}

-(LoggerMessageCell *)messageCell
{
	return _targetCell;
}

-(void)setMessageCell:(LoggerMessageCell *)aCell
{
	if(_targetCell != aCell)
	{
		[aCell retain];
		[_targetCell release],_targetCell = nil;
		_targetCell = aCell;
	}
}

-(void)didTurnIntoFault
{
	if(_targetCell != nil && !_isReadImageTriggered)
	{
		MTLogError(@"%s this really shouldn't happen",__PRETTY_FUNCTION__);
		[_targetCell release],_targetCell = nil;
	}

	[super didTurnIntoFault];
}

-(void)dealloc
{
	if(_targetCell != nil && !_isReadImageTriggered)
	{
		MTLogError(@"%s this really shouldn't happen",__PRETTY_FUNCTION__);
		[_targetCell release],_targetCell = nil;
	}
	
	[super dealloc];
}


-(LoggerMessageType)dataType
{
	LoggerMessageType type = (LoggerMessageType)[[self contentsType] shortValue];
	return type;
}


-(void)imageForCell:(LoggerMessageCell *)aCell
{

	LoggerMessageType type = [self dataType];

	//now store datas
	if(type != kMessageImage)
		return;

	MTLogVerify(@"%s %p %@",__PRETTY_FUNCTION__,aCell,[self dataFilepath]);
	
	[self setMessageCell:aCell];
	
	if(!_isReadImageTriggered)
	{
		_isReadImageTriggered = YES;

		[[LoggerDataStorage sharedDataStorage]
		 readDataFromPath:[self dataFilepath]
		 forType:type
		 withResult:^(NSData *aData) {
			dispatch_async(dispatch_get_main_queue(), ^{
				MTLogAssert(@"%s read done # of cells : %p, image : %@",__PRETTY_FUNCTION__, [self messageCell], [self dataFilepath]);
				if(aData != nil && [aData length])
				{
					[[self messageCell] setImagedata:aData forRect:CGRectZero];
				}
				// release the cell after use
				[self setMessageCell:nil];
				_isReadImageTriggered = NO;
			});
		 }];
	}
}

-(void)cancelImageForCell:(LoggerMessageCell *)aCell
{
	LoggerMessageType type = [self dataType];
	
	//now store datas
	if(type != kMessageImage)
		return;

	MTLogError(@"%s %p",__PRETTY_FUNCTION__,aCell);
	
	[self setMessageCell:nil];
}


@end
