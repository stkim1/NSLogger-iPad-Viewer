/*
 *
 * BSD license follows (http://www.opensource.org/licenses/bsd-license.php)
 *
 * Copyright (c) 2012-2013 Sung-Taek, Kim <stkim1@colorfulglue.com> All Rights Reserved.
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

#import "LoggerCertManager.h"
#import <Security/SecItem.h>

@interface LoggerCertManager()
@property (nonatomic, retain) NSError *errorLoadingCert;
- (CFArrayRef)_loadIdentityFromKeyChain:(NSString*)inStrCertPath  error:(NSError **)outError;
@end

@implementation LoggerCertManager
{
	NSError			*_errorLoadingCert;
    CFArrayRef		_serverCerts;
	BOOL			_serverCertsLoadAttempted;
}
@synthesize errorLoadingCert = _errorLoadingCert;
@synthesize serverCerts = _serverCerts;
@synthesize serverCertsLoadAttempted = _serverCertsLoadAttempted;

static const UInt8 kKeychainCertificateID[] = "NSLogger SSL\0";

-(id)init
{
	self = [super init];
	if(self)
	{
		_serverCerts = NULL;
		_serverCertsLoadAttempted = NO;
	}
	
	return self;
}

-(void)dealloc
{
	if(_serverCerts != NULL)
		CFRelease(_serverCerts);

	[super dealloc];
}

// -----------------------------------------------------------------------------
#pragma mark -
#pragma mark SSL support
// -----------------------------------------------------------------------------
- (CFArrayRef)_loadIdentityFromKeyChain:(NSString*)inStrCertPath error:(NSError **)outError
{
	
	SecIdentityRef			identityRef			= NULL;
	SecCertificateRef		certificateRef		= NULL;
	
    CredentialImportStatus  status;
	CFStringRef				identityLabel		= NULL;
	
	NSDictionary			*identitySearchQuery = nil;
	OSStatus				keychainErr			= noErr;
	
	NSData					*fileData			= nil;
	CFArrayRef              importedPkcs12		= NULL;
    OSStatus                importError			= noErr;
	NSDictionary			*importOptions		= nil;
	
	NSDictionary			*identityAddQuery	= nil;
	OSStatus                identityError		= noErr;
		
	if (outError != NULL)
		*outError = nil;
	
    identityLabel = \
		CFStringCreateWithCString(NULL
								  ,(const char *)kKeychainCertificateID
								  ,kCFStringEncodingUTF8);

	// Set up a keychain search dictionary:
	identitySearchQuery =
		// This keychain item is an identity
		@{(id)kSecClass:(id)kSecClassIdentity
		// target one, specific identity label
		,(id)kSecAttrLabel:(id)identityLabel
		// Since every iOS app will have their own keychain,
		// there should be only one identity in it.
		// b/c You are going to act as a server, and you cannot have two identity.
		,(id)kSecMatchLimit:(id)kSecMatchLimitOne
		// return certificate reference
		,(id)kSecReturnRef:(id)kCFBooleanTrue};
	
	// If the keychain item exists, return the attributes of the item:
	keychainErr =
		SecItemCopyMatching((CFDictionaryRef)identitySearchQuery
							,(CFTypeRef *)(&identityRef));
	
	if (keychainErr == noErr)
	{
		if (SecIdentityCopyCertificate(identityRef, &certificateRef) == noErr)
		{
			CFStringRef certSummary = \
				SecCertificateCopySubjectSummary(certificateRef);
			if (certSummary != NULL)
			{
				if(CFStringCompare(certSummary, identityLabel, 0) == kCFCompareEqualTo)
				{
					NSLog(@"cert found!");
					status = kCredentialImportStatusSucceeded;
				}

				CFRelease(certSummary);
			}
		}
	}
	
	// cert, and id found
	if(status == kCredentialImportStatusSucceeded)
	{
		CFRelease(identityLabel);
		// We found our identity
		CFTypeRef values[] = {identityRef, certificateRef};
		return CFArrayCreate(NULL, values, 2, &kCFTypeArrayCallBacks);
	}
	
	// Anything other than 'errSecItemNotFound' atm is a significant error
	assert(keychainErr == errSecItemNotFound);
	
	// check file path is not nil
	
	assert(inStrCertPath != nil);
	assert([inStrCertPath length] != 0);
	assert(![inStrCertPath isEqual:[NSNull null]]);
	
	//prepare x.509 cert + private key (.pkcs#12 format) import
	fileData = \
		[NSData
		 dataWithContentsOfFile:
		 [[NSBundle mainBundle]
		  pathForResource:inStrCertPath
		  ofType:@"p12"]];
	
	assert(fileData != nil);
	
    status = kCredentialImportStatusFailed;
	
	importOptions = @{(id)kSecImportExportPassphrase:@""};
	importError = SecPKCS12Import((CFDataRef)fileData,
								  (CFDictionaryRef)importOptions,
								  &importedPkcs12);
	
    if (importError == noErr)
	{
		for (NSDictionary * itemDict in (id)importedPkcs12)
		{
            assert([itemDict isKindOfClass:[NSDictionary class]]);
			
            identityRef = \
				(SecIdentityRef)[itemDict objectForKey:(NSString *)kSecImportItemIdentity];
            assert(identityRef != NULL);
            assert(CFGetTypeID(identityRef) == SecIdentityGetTypeID());
			
			identityAddQuery = \
				// identity label
				@{(id)kSecAttrLabel:(id)identityLabel
				// identity value
				,(id)kSecValueRef:(id)identityRef};
			
            identityError = SecItemAdd((CFDictionaryRef)identityAddQuery,NULL);
			
			if ( (identityError == errSecSuccess) || \
				(identityError == errSecDuplicateItem))
			{
				if (SecIdentityCopyCertificate(identityRef, &certificateRef) == noErr)
				{
					NSLog(@"cert imported!");
					status = kCredentialImportStatusSucceeded;
					break;
				}
			}
		}
		
		// since you are not the owner, you cannot release it... my bad
		//CFRelease(importedPkcs12);
	}
	
	// release idendity label
	CFRelease(identityLabel);
	
	if(status == kCredentialImportStatusSucceeded)
	{
		// We found our identity
		CFTypeRef values[] = {identityRef, certificateRef};
		return CFArrayCreate(NULL, values, 2, &kCFTypeArrayCallBacks);
	}
	
	NSString *errMsg =
		[NSString stringWithFormat:
		 NSLocalizedString(@"Our private encryption certificate could not be loaded (%@, search error %ld import error %ld identity error %ld)", @"")
		 ,NSLocalizedString(@"Failed retrieving our self-signed certificate", @"")
		 ,keychainErr
		 ,importError
		 ,identityError];
	
	NSDictionary*	dictUserInfo = \
		@{NSLocalizedDescriptionKey:NSLocalizedString(@"NSLogger won't be able to accept SSL connections", @"")
		,NSLocalizedFailureReasonErrorKey:errMsg
		,NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString(@"Please contact the application developers", @"")};
	
	*outError = [NSError
				 errorWithDomain:NSOSStatusErrorDomain
				 code:status
				 userInfo:dictUserInfo];

	return NULL;
}


// loadEncryptionCertificate gets called mutiple times from LoggerTransport object
// To handle them, we need to save the error and result and return whenver asked.
- (BOOL)loadEncryptionCertificate:(NSError **)outError;
{
	if(_serverCertsLoadAttempted)
	{
		// return the error from the previous attempt
		*outError = _errorLoadingCert;
		return (_serverCerts != NULL);
	}

	_serverCertsLoadAttempted = YES;

	NSError *loadingError = nil;
	
	_serverCerts =
		[self
		 _loadIdentityFromKeyChain:@"NSLoggerResource.bundle/Certificate/NSLoggerCert"
		 error:&loadingError];

	// retain the error and return it next time
	self.errorLoadingCert = loadingError;
	
	*outError = loadingError;

	return (_serverCerts != NULL);
}


@end
