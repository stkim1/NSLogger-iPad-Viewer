//
//  LoggerCertManager
//  ipadnslogger
//
//  Created by Almighty Kim on 10/26/12.
//  Copyright (c) 2012 Colorful Glue. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    kCredentialImportStatusCancelled,
    kCredentialImportStatusFailed,
    kCredentialImportStatusSucceeded
} CredentialImportStatus;

@interface LoggerCertManager : NSObject
@property (nonatomic, readonly) CFArrayRef serverCerts;
@property (nonatomic, readonly) BOOL serverCertsLoadAttempted;
- (BOOL)loadEncryptionCertificate:(NSError **)outError;
@end
