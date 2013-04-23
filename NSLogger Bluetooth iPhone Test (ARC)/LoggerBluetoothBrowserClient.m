/*
 *
 * Modified BSD license.
 *
 * Copyright (c) 2012-2013 Sung-Taek, Kim <stkim1@colorfulglue.com> All Rights
 * Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Any redistribution is done solely for personal benefit and not for any
 *    commercial purpose or for monetary gain
 *
 * 4. No binary form of source code is submitted to App Store℠ of Apple Inc.
 *
 * 5. Neither the name of the Sung-Taek, Kim nor the names of its contributors
 *    may be used to endorse or promote products derived from  this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL COPYRIGHT HOLDER AND AND CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 */

#include "LoggerBluetoothBrowserClient.h"
#include "LoggerCommon.h"
#include <dns_util.h>
#include <dns_sd.h>
#include <CoreFoundation/CoreFoundation.h>

static DNSServiceRef				sdResolvRef;
static CFSocketRef					sdResolvSocket;

static DNSServiceRef				sdBrowserRef;
static CFSocketRef					sdBrowserSocket;

static void
SDRefResolveReply(DNSServiceRef,DNSServiceFlags,uint32_t,DNSServiceErrorType,const char*,const char*,uint16_t,uint16_t,const unsigned char*,void*);

static void
SDRefResolveSocket(CFSocketRef,CFSocketCallBackType,CFDataRef,const void*,void*);

static void
start_resolve(DNSServiceFlags,uint32_t,const char*,const char*,const char*);

static void
destory_resolve_ref(void);

static void
SDRefBrowseReply(DNSServiceRef,DNSServiceFlags,uint32_t,DNSServiceErrorType,const char*,const char*,const char*,void*);

static void
SDRefBrowseSocket(CFSocketRef,CFSocketCallBackType,CFDataRef,const void*,void*);


//------------------------------------------------------------------------------
#pragma mark - DNS-SD Resolving
//------------------------------------------------------------------------------

// Called by DNS-SD when something happens with the resolve operation.
void
SDRefResolveReply(DNSServiceRef				sdRef,
				  DNSServiceFlags			flags,
				  uint32_t					interfaceIndex,
				  DNSServiceErrorType		errorCode,
				  const char				*fullname,
				  const char				*hosttarget,
				  uint16_t					port,
				  uint16_t					txtLen,
				  const unsigned char		*txtRecord,
				  void						*context)
{
    if (errorCode == kDNSServiceErr_NoError)
	{
		[[[UIAlertView alloc]
		  initWithTitle:[NSString stringWithUTF8String:hosttarget]
		  message:
			[NSString
			 stringWithFormat:@"DNSServiceFlags %d\ninterfaceIndex %d\nDNSServiceErrorType %d\nfullname %s\n port %d"
			 ,flags,interfaceIndex,errorCode,fullname,ntohs(port)]
		  delegate:nil
		  cancelButtonTitle:@"Ok"
		  otherButtonTitles: nil] show];
    }

	// once job done, destory resolve reference
	destory_resolve_ref();
}

void
SDRefResolveSocket(CFSocketRef				s,
				   CFSocketCallBackType		type,
				   CFDataRef				address,
				   const void				*data,
				   void						*info)
{
	DNSServiceErrorType err = 0;
	err = DNSServiceProcessResult(sdResolvRef);
    if (err != kDNSServiceErr_NoError)
	{
		printf("DNSServiceProcessResult error %d",err);
		destory_resolve_ref();
    }
}

// Starts a resolve.  Starting a resolve on a service that is currently resolving is a no-op.
void
start_resolve(DNSServiceFlags		flags,
			  uint32_t				interfaceIndex,
			  const char			*serviceName,
			  const char			*regtype,
			  const char			*replyDomain)
{
	DNSServiceErrorType errorCode;
    int                 fd;
    CFSocketContext     context = { 0, NULL, NULL, NULL, NULL };
    CFRunLoopSourceRef  rls;
	CFOptionFlags		socketFlag;

    if (sdResolvRef == NULL)
	{
        errorCode =
			DNSServiceResolve(&sdResolvRef,
							  flags,
							  interfaceIndex,
							  serviceName,
							  regtype,
							  replyDomain,
							  SDRefResolveReply,
							  NULL);

		// Create a CFSocket to handle incoming messages associated with the
		// DNSServiceRef.
		if (errorCode == kDNSServiceErr_NoError)
		{
			assert(sdResolvRef != NULL);
			
			fd = DNSServiceRefSockFD(sdResolvRef);
			assert(fd >= 0);
			
			assert(sdResolvSocket == NULL);
			sdResolvSocket =
				CFSocketCreateWithNative(NULL,
										 fd,
										 kCFSocketReadCallBack,
										 SDRefResolveSocket,
										 &context);
			assert(sdResolvSocket != NULL);
			
			socketFlag = CFSocketGetSocketFlags(sdResolvSocket);
			socketFlag = socketFlag &~ (CFOptionFlags)kCFSocketCloseOnInvalidate;
			CFSocketSetSocketFlags(sdResolvSocket,socketFlag);
			
			rls = CFSocketCreateRunLoopSource(NULL,sdResolvSocket, 0);
			assert(rls != NULL);
			
			CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
			CFRelease(rls);
		}

		// if anything goes wrong, destory resolve stack
        if (errorCode != kDNSServiceErr_NoError)
		{
			destory_resolve_ref();
        }
    }
}

void
destory_resolve_ref(void)
{
	if (sdResolvSocket != NULL)
	{
        CFSocketInvalidate(sdResolvSocket);
        CFRelease(sdResolvSocket);
        sdResolvSocket = NULL;
    }
	
	if (sdResolvRef != NULL)
	{
        DNSServiceRefDeallocate(sdResolvRef);
        sdResolvRef = NULL;
    }
}

//------------------------------------------------------------------------------
#pragma mark - DNS-SD Browsing
//------------------------------------------------------------------------------
void
SDRefBrowseReply(DNSServiceRef			sdRef,
				 DNSServiceFlags		flags,
				 uint32_t				interfaceIndex,
				 DNSServiceErrorType	errorCode,
				 const char				*serviceName,
				 const char				*regtype,
				 const char				*replyDomain,
				 void					*context)
{
	
/*
	printf("DNSServiceFlags %d",flags);
	printf("interfaceIndex %d",interfaceIndex);
	printf("DNSServiceErrorType %d",errorCode);
	printf("serviceName %s",serviceName);
	printf("regtype %s",regtype);
	printf("replyDomain %s",replyDomain);
*/	

	if (errorCode == kDNSServiceErr_NoError)
	{
		[[[UIAlertView alloc]
		  initWithTitle:[NSString stringWithUTF8String:serviceName]
		  message:[NSString stringWithFormat:@"DNSServiceFlags %d\ninterfaceIndex %d\nDNSServiceErrorType %d\nregtype %s\nreplyDomain %s"
				   ,flags ,interfaceIndex,errorCode,regtype,replyDomain]
		  delegate:nil
		  cancelButtonTitle:@"Ok"
		  otherButtonTitles: nil] show];
		
		start_resolve(flags, interfaceIndex, serviceName, regtype, replyDomain);
		
		
    }
	else
	{
		stop_browsing();
    }

}


// A CFSocket callback.  This runs when we get messages from mDNSResponder
// regarding our DNSServiceRef.  We just turn around and call DNSServiceProcessResult,
// which does all of the heavy lifting (and would typically call QueryRecordCallback).
void
SDRefBrowseSocket(CFSocketRef			s,
				  CFSocketCallBackType	type,
				  CFDataRef				address,
				  const void			*data,
				  void					*info)
{
	DNSServiceErrorType err = 0;
	err = DNSServiceProcessResult(sdBrowserRef);
    if (err != kDNSServiceErr_NoError)
	{
		printf("DNSServiceProcessResult error %d",err);
		stop_browsing();
    }
}

void
start_browsing(bool ssl_connection)
{
	DNSServiceErrorType errorType	= kDNSServiceErr_NoError;
    int                 fd;
    CFSocketContext     context = { 0, NULL, NULL, NULL, NULL };
    CFRunLoopSourceRef  rls;
	CFOptionFlags		socketFlag;

	CFStringRef			regTypeStr = (ssl_connection)? LOGGER_SERVICE_TYPE_SSL : LOGGER_SERVICE_TYPE;
	const char			*regType = CFStringGetCStringPtr(regTypeStr, kCFStringEncodingMacRoman);

	printf("start browsing... for %s\n",regType);
    sdBrowserRef = NULL;

    // Create the DNSServiceRef to run our query.
	errorType =
		DNSServiceBrowse(&sdBrowserRef,
						 kDNSServiceFlagsIncludeP2P,
						 kDNSServiceInterfaceIndexP2P,
						 regType,
						 NULL,
						 SDRefBrowseReply,
						 NULL);
	printf("DNSServiceBrowse result %d\n",errorType);

    // Create a CFSocket to handle incoming messages associated with the
    // DNSServiceRef.
    if (errorType == kDNSServiceErr_NoError)
	{
        assert(sdBrowserRef != NULL);

        fd = DNSServiceRefSockFD(sdBrowserRef);
        assert(fd >= 0);

        assert(sdBrowserSocket == NULL);
		sdBrowserSocket =
			CFSocketCreateWithNative(NULL,
									 fd,
									 kCFSocketReadCallBack,
									 SDRefBrowseSocket,
									 &context);
        assert(sdBrowserSocket != NULL);
        
		socketFlag = CFSocketGetSocketFlags(sdBrowserSocket);
		socketFlag = socketFlag &~ (CFOptionFlags)kCFSocketCloseOnInvalidate;
        CFSocketSetSocketFlags(sdBrowserSocket,socketFlag);
		
        rls = CFSocketCreateRunLoopSource(NULL,sdBrowserSocket, 0);
        assert(rls != NULL);

        CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
        CFRelease(rls);
    }

    if (errorType != kDNSServiceErr_NoError)
	{
		printf("DNSService Error %d",errorType);
		stop_browsing();
    }
}

void stop_browsing(void)
{
	destory_resolve_ref();
	
	if (sdBrowserSocket != NULL)
	{
        CFSocketInvalidate(sdBrowserSocket);
        CFRelease(sdBrowserSocket);
        sdBrowserSocket = NULL;
    }
	
    if (sdBrowserRef != NULL)
	{
        DNSServiceRefDeallocate(sdBrowserRef);
        sdBrowserRef = NULL;
    }
	
}