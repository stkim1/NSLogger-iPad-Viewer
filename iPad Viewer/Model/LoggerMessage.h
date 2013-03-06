/*
 * LoggerMessage.h
 *
 * BSD license follows (http://www.opensource.org/licenses/bsd-license.php)
 * 
 * Copyright (c) 2010-2011 Florent Pillet <fpillet@gmail.com> All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * Redistributions of  source code  must retain  the above  copyright notice,
 * this list of  conditions and the following  disclaimer. Redistributions in
 * binary  form must  reproduce  the  above copyright  notice,  this list  of
 * conditions and the following disclaimer  in the documentation and/or other
 * materials  provided with  the distribution.  Neither the  name of  Florent
 * Pillet nor the names of its contributors may be used to endorse or promote
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
#include <time.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LoggerConstModel.h"

#import "LoggerMessageHeight.h"
#import "LoggerClientHeight.h"
#import "LoggerMarkerHeight.h"

//#define SUPPORT_LADNSACPE_DISPLAY

@class LoggerConnection;

@interface LoggerMessage : NSObject
{
	struct timeval				timestamp;		// full timestamp (seconds & microseconds)
    
	NSString					*tag;
	NSString					*filename;
	NSString					*functionName;
	NSMutableDictionary			*parts;			// for non-standard parts transmitted by the clients, store the data in this dictionary
	id							message;		// NSString, NSData or image data
	UIImage						*image;			// if the message is an image, the image gets decoded once it's being accessed
    
	NSUInteger					sequence;		// message's number if order of reception
    
	NSString					*threadID;
    
	int							lineNumber;		// line number in the file, if filename != nil
    
	short						level;
	short						type;
	short						contentsType;	// the type of message data (string, data, image)
    
	// unsaved cached data
	CGSize						imageSize;

	NSString					*_textRepresentation; // text representation of this message
	// stkim1_jan.18,2013
	// width of cells in iOS version is fixed so we can pre-calculate and cache
	// heights for two orientations at messageProcessingQueue of LoggerConnection
	CGFloat						_portraitHeight;
	CGFloat						_landscapeHeight;
}
@property (nonatomic, assign) struct timeval		timestamp;
@property (nonatomic, retain) NSString				*tag;
@property (nonatomic, retain) NSString				*filename;
@property (nonatomic, retain) NSString				*functionName;
@property (nonatomic, retain) NSDictionary			*parts;
@property (nonatomic, retain) id					message;
@property (nonatomic, retain) UIImage				*image;
@property (nonatomic, readonly) NSUInteger			sequence;
@property (nonatomic, retain) NSString				*threadID;
@property (nonatomic, assign) int					lineNumber;
@property (nonatomic, assign) short					level;
@property (nonatomic, assign) short					type;
@property (nonatomic, assign) short					contentsType;
@property (nonatomic, readonly) CGSize				imageSize;
@property (nonatomic, readonly) NSString			*textRepresentation;
@property (nonatomic, readonly) NSString			*messageText;
@property (nonatomic, readonly) NSString			*messageType;
@property (nonatomic, readonly) CGFloat				portraitHeight;
@property (nonatomic, readonly) CGFloat				landscapeHeight;

- (void)computeTimeDelta:(struct timeval *)td since:(LoggerMessage *)previousMessage;

@end