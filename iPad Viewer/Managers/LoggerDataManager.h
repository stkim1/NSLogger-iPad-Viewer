//
//  LoggerDataManager.h
//  LoggerData
//
//  Created by Almighty Kim on 12/1/12.
//  Copyright (c) 2012 Colorful Glue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoggerConnection.h"

@interface LoggerDataManager : NSObject <LoggerConnectionDelegate>
+(LoggerDataManager *)sharedDataManager;
@property (nonatomic, readonly) NSManagedObjectContext *messageDisplayContext;
@end
