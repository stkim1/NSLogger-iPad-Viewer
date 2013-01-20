//
//  LoggerMessageData.h
//  ipadnslogger
//
//  Created by Almighty Kim on 1/19/13.
//  Copyright (c) 2013 Colorful Glue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#include "LoggerConstModel.h"

@interface LoggerMessageData : NSManagedObject

@property (nonatomic) int16_t contentsType;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSString * functionName;
@property (nonatomic, retain) NSString * imageSize;
@property (nonatomic) float landscapeHeight;
@property (nonatomic) int16_t level;
@property (nonatomic) float portraitHeight;
@property (nonatomic) int32_t sequence;
@property (nonatomic, retain) NSString * tag;
@property (nonatomic, retain) NSString * threadID;
@property (nonatomic) int64_t timestamp;
@property (nonatomic) int16_t type;
@property (nonatomic) int32_t lineNumber;
@property (nonatomic, retain) NSString * messageText;
@property (nonatomic, retain) NSString * messageType;
@property (nonatomic, retain) NSString * textRepresentation;

@end
