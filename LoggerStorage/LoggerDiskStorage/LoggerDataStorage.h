//
//  LoggerDataStorage.h
//  LoggerStorage
//
//  Created by Almighty Kim on 12/16/12.
//  Copyright (c) 2012 Colorful Glue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoggerClient.h"

@interface LoggerDataStorage : NSObject
-(void)writeData:(NSData *)aData toPath:(NSString *)aFilepath;
-(void)readDataFromPath:(NSString *)aPath forResult:(void (^)(NSData *aData))aResultHandler;
-(void)deleteWholePath:(NSString *)aPath;
@end
