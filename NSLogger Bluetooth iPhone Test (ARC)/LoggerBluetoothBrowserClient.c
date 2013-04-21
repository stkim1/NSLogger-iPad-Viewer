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

static DNSServiceRef	_sdRef;
static CFSocketRef		_sdRefSocket;

static void
SDRefBrowseReply(DNSServiceRef			sdRef,
				 DNSServiceFlags		flags,
				 uint32_t				interfaceIndex,
				 DNSServiceErrorType	errorCode,
				 const char				*serviceName,
				 const char				*regtype,
				 const char				*replyDomain,
				 void					*context)
{
	printf("serviceName %s",serviceName);
	printf("regtype %s",regtype);
	printf("replyDomain %s",replyDomain);
}


// A CFSocket callback.  This runs when we get messages from mDNSResponder
// regarding our DNSServiceRef.  We just turn around and call DNSServiceProcessResult,
// which does all of the heavy lifting (and would typically call QueryRecordCallback).
static void
SDRefSocketCallback(CFSocketRef             s,
					CFSocketCallBackType    type,
					CFDataRef               address,
					const void				*data,
					void					*info)
{
}


void
start_browsing(bool ssl_connection)
{
    DNSServiceErrorType err;
    int                 fd;
    CFSocketContext     context = { 0, NULL, NULL, NULL, NULL };
    CFRunLoopSourceRef  rls;
	CFOptionFlags		socketFlag;
	CFStringRef			regTypeStr = (ssl_connection)? LOGGER_SERVICE_TYPE_SSL : LOGGER_SERVICE_TYPE;
	const char			*regType = CFStringGetCStringPtr(regTypeStr, kCFStringEncodingMacRoman);

    assert(_sdRef == NULL);
	printf("start browsing...");

    
    // Create the DNSServiceRef to run our query.
    
    err = kDNSServiceErr_NoError;

    if (err == kDNSServiceErr_NoError)
	{
        err =
		DNSServiceBrowse(&_sdRef,
						 kDNSServiceFlagsIncludeP2P,
						 kDNSServiceInterfaceIndexP2P,
						 regType,
						 NULL,
						 SDRefBrowseReply,
						 NULL);
	}
	
    // Create a CFSocket to handle incoming messages associated with the
    // DNSServiceRef.
    if (err == kDNSServiceErr_NoError)
	{
        assert(_sdRef != NULL);

        fd = DNSServiceRefSockFD(_sdRef);
        assert(fd >= 0);
        
        assert(_sdRefSocket == NULL);
        _sdRefSocket = CFSocketCreateWithNative(NULL,
												fd,
												kCFSocketReadCallBack,
												SDRefSocketCallback,
												&context);
        assert(_sdRefSocket != NULL);
        
		socketFlag = CFSocketGetSocketFlags(_sdRefSocket);
		socketFlag = socketFlag &~ (CFOptionFlags)kCFSocketCloseOnInvalidate;
        CFSocketSetSocketFlags(_sdRefSocket,socketFlag);
        rls = CFSocketCreateRunLoopSource(NULL,_sdRefSocket, 0);
        assert(rls != NULL);
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
        CFRelease(rls);
    }

    if (err != kDNSServiceErr_NoError)
	{
		printf("DNSService Error %d",err);
    }
}
