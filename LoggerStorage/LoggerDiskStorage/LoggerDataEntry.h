//
//  LoggerDataEntry.h
//  LoggerStorage
//
//  Created by Almighty Kim on 1/8/13.
//  Copyright (c) 2013 Colorful Glue. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LoggerDataEntry : NSObject
@property (nonatomic, readonly) NSString			*filepath;
@property (nonatomic, readonly) NSString			*dirOfFilepath;
@property (nonatomic, readonly) NSMutableArray		*operationQueue;
@property (nonatomic, retain)	NSData				*data;

-(id)initWithFilepath:(NSString *)aFilepath;
@end
