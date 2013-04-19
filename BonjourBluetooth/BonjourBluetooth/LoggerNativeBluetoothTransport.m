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

#import "LoggerNativeBluetoothTransport.h"
#include <dns_sd.h>
#include <dns_util.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <netinet/in.h>


// Default Bonjour service identifiers
static const char * const bluetooth_service_type_ssl = "_nslogger-bluetooth-ssl._tcp";
static const char * const bluetooth_service_type = "_nslogger-bluetooth._tcp";
static const char * const bluetooth_service_name = "NSLogger-Viewer-Bluetooth";

#define BLUETOOTH_INIT_PORT 49152

@interface LoggerNativeBluetoothTransport()
-(void)startListening;
-(void)setupBluetoothStack;
-(void)destroyBluetoothStack;

static void
serviceRegisterCallback(DNSServiceRef,DNSServiceFlags,DNSServiceErrorType,const char*,const char*,const char*,void*);

static void
SDRefSocketCallback(CFSocketRef,CFSocketCallBackType,CFDataRef,const void *,void*);

static NSUInteger
listen_on_port(int, NSUInteger*, sa_family_t);
@end

@implementation LoggerNativeBluetoothTransport
{
	DNSServiceRef		_sdServiceRef;
	CFSocketRef			_listenerSocket_sd_ipv4;
	
	NSThread			*_listenerThread;
	NSNetService		*_bonjourService;
	NSString			*_bonjourServiceName;
	
	int					_listenerPort;
	BOOL				_publishBonjourService;
	CFSocketRef			_listenerSocket_ipv4;
	CFSocketRef			_listenerSocket_ipv6;
}
@synthesize listenerPort = _listenerPort;
@synthesize publishBonjourService = _publishBonjourService;
@synthesize listenerSocket_sd_ipv4 = _listenerSocket_sd_ipv4;

- (void)dealloc
{
	[_listenerThread cancel];
	[_bonjourService release];
	[_bonjourServiceName release];
	[super dealloc];
}

-(void)start
{
	// start with port 0
	_listenerPort = 0;
	
	NSLog(@"bluetooth service started");
	// now we're going into multi-threaded mode for listening
	[NSThread
	 detachNewThreadSelector:@selector(startListening)
	 toTarget:self
	 withObject:nil];
}

-(void)stop
{
	if(_listenerThread == nil)
	{
		return;
	}

	if([NSThread currentThread] != _listenerThread)
	{
		[self
		 performSelector:_cmd
		 onThread:_listenerThread
		 withObject:nil
		 waitUntilDone:YES];
	}
	
	// tear apart bluetooth connection
	[self destroyBluetoothStack];
	
	[_listenerThread cancel];
	_listenerThread = nil;
}

-(void)startListening
{
	NSLog(@"run listening thread...");

	_listenerThread = [NSThread currentThread];
	[[_listenerThread threadDictionary]
	 setObject:[NSRunLoop currentRunLoop] forKey:@"runLoop"];
	
	NSAutoreleasePool *outerPool = [[NSAutoreleasePool alloc] init];
	
	// setup here
	[self setupBluetoothStack];
	
	while (![_listenerThread isCancelled])
	{
		NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
		[[NSRunLoop currentRunLoop] run];
		[innerPool release];
	}
	
	[outerPool release];
	_listenerThread = nil;
}

static void
serviceRegisterCallback(DNSServiceRef			sdRef,
						DNSServiceFlags			flags,
						DNSServiceErrorType		errorCode,
						const char				*name,
						const char				*regtype,
						const char				*domain,
						void					*context)

{
	NSLog(@"%s %s %s %s",__PRETTY_FUNCTION__,name,regtype, domain);

	LoggerNativeBluetoothTransport *callbackSelf = (LoggerNativeBluetoothTransport *) context;
    assert([callbackSelf isKindOfClass:[LoggerNativeBluetoothTransport class]]);
    assert(sdRef == callbackSelf->_sdServiceRef);
    assert(flags & kDNSServiceFlagsAdd);
	
    if (errorCode == kDNSServiceErr_NoError)
	{
		NSLog(@"errorCode : kDNSServiceErr_NoError");
		NSLog(@"service is now assigned");

		
		// We're assuming SRV records over unicast DNS here, so the first result packet we get
        // will contain all the information we're going to get.  In a more dynamic situation
        // (for example, multicast DNS or long-lived queries in Back to My Mac) we'd would want
        // to leave the query running.
        
        if ( !(flags & kDNSServiceFlagsAdd) )
		{
			NSLog(@"flags does not include kDNSServiceFlagsAdd %x",flags);
            //[callbackSelf stopWithError:nil];
        }
    } else {
		NSLog(@"errorCode is NOT kDNSServiceErr_NoError");
        //[callbackSelf stopWithDNSServiceError:errorCode];
    }
	
}


static void
SDRefSocketCallback(CFSocketRef             s,
					CFSocketCallBackType    type,
					CFDataRef               address,
					const void				*data,
					void					*info)

// A CFSocket callback.  This runs when we get messages from mDNSResponder
// regarding our DNSServiceRef.  We just turn around and call DNSServiceProcessResult,
// which does all of the heavy lifting (and would typically call QueryRecordCallback).
{
    DNSServiceErrorType errorType;
    LoggerNativeBluetoothTransport	*callbackSelf = \
		(LoggerNativeBluetoothTransport *)info;

    assert(type == kCFSocketReadCallBack);
    assert([callbackSelf isKindOfClass:[callbackSelf class]]);
    assert(s == callbackSelf->_listenerSocket_sd_ipv4);
    
    errorType = DNSServiceProcessResult(callbackSelf->_sdServiceRef);
    if (errorType != kDNSServiceErr_NoError)
	{
		NSLog(@"there is an error with socket callback %x",errorType);
		//[obj stopWithDNSServiceError:err];
		[callbackSelf destroyBluetoothStack];
    }
}

static NSUInteger
listen_on_port(int fd, NSUInteger *boundPort, sa_family_t address_family)
{
    int						err			= 0;
    struct sockaddr_storage	addr;
    struct sockaddr_in		*addr4Ptr	= NULL;
	struct sockaddr_in6		*addr6Ptr	= NULL;
    socklen_t				addrLen;
	const int				yes			= 1;

	NSLog(@"socket description id %d",fd);
	
// if querying port is to be 0, you should not set socket option
#if 0
	//0. set socket option
	err = setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));
	if (err < 0)
	{
		err = errno;
	}
	NSLog(@"set socket option result %d",err);
#endif
	
	//1. Bind the socket to port 0 which causes the kernel to choose a port
	memset(&addr, 0, sizeof(addr));
	addr.ss_family = address_family;
	switch (address_family)
	{
		case AF_INET:{
			addr4Ptr			= (struct sockaddr_in *)&addr;
			addr4Ptr->sin_len	= sizeof(*addr4Ptr);
			addr4Ptr->sin_port	= htons(0);
			addr4Ptr->sin_addr.s_addr = htonl(INADDR_ANY);
			err	= bind(fd, (const struct sockaddr *)&addr, addr.ss_len);
			break;
		}
		case AF_INET6:{
			addr6Ptr			= (struct sockaddr_in6 *)&addr;
			addr6Ptr->sin6_len  = sizeof(*addr6Ptr);
			addr6Ptr->sin6_port = htons(0);
			memcpy(&(addr6Ptr->sin6_addr), &in6addr_any, sizeof(addr6Ptr->sin6_addr));
			err	= bind(fd, (const struct sockaddr *)&addr, addr.ss_len);
			break;
		}
		default:
			break;
	}
	if (err < 0)
	{
		err = errno;
	}
	NSLog(@"1. bound result %d",err);

	//2. listen to port kernel has choosen for us
	if (err == 0)
	{
		err = listen(fd, 5);
		if (err < 0)
		{
			err = errno;
		}
	}
	NSLog(@"2. listen result %d",err);

	//3. Figure out what port we actually bound too.
	if (err == 0)
	{
		addrLen = sizeof(addr);
		err = getsockname(fd, (struct sockaddr *)&addr, &addrLen);
		if (err < 0)
		{
			err = errno;
		}
		else
		{
			switch (address_family)
			{
				case AF_INET:{
					*boundPort = ntohs(((const struct sockaddr_in *) &addr)->sin_port);
					break;
				}
				case AF_INET6:{
					*boundPort = ntohs(((const struct sockaddr_in6 *) &addr)->sin6_port);
					break;
				}
				default:
					break;
			}
		}
	}
	NSLog(@"3. port found %d %d",*boundPort, err);

    return err;
}


-(void)setupBluetoothStack
{
	DNSServiceErrorType errorType	= kDNSServiceErr_NoError;
    int                 fd			= 0;
    CFSocketContext     context		= { 0, (void *)self, NULL, NULL, NULL };
    CFRunLoopSourceRef  runLoopSource = NULL;
    NSUInteger			boundPort	= 0;

	assert(self->_sdServiceRef == NULL);
	
	errorType =
		DNSServiceRegister(
					   &(self->_sdServiceRef),		// sdRef
					   kDNSServiceFlagsIncludeP2P,	// interfaceIndex. kDNSServiceInterfaceIndexP2P does not have meanning when serving
					   0,							// flags
					   bluetooth_service_name,		// name
					   bluetooth_service_type,		// regtype
					   NULL,						// domain
					   NULL,						// host
					   BLUETOOTH_INIT_PORT,			// port. just for bt init
					   0,							// txtLen
					   NULL,						// txtRecord
					   serviceRegisterCallback,		// callBack,
					   (void *)(self)				// context
					   );
	
	
    if (errorType == kDNSServiceErr_NoError)
	{
		NSLog(@"we successfully announced service on bluetooth");

        assert(self->_sdServiceRef != NULL);
        fd = DNSServiceRefSockFD(self->_sdServiceRef);
        assert(fd >= 0);

		// setup service socket
        assert(self->_listenerSocket_sd_ipv4 == NULL);
		
#if 0
        self->_listenerSocket_sd_ipv4 = \
			CFSocketCreateWithNative(NULL,
									 fd,
									 kCFSocketReadCallBack,
									 SDRefSocketCallback,
									 &context);
#else
        self->_listenerSocket_sd_ipv4 = \
			CFSocketCreateWithNative(kCFAllocatorDefault,
									 fd,
									 kCFSocketAcceptCallBack,
									 SDRefSocketCallback,
									 &context);
#endif
        assert(self->_listenerSocket_sd_ipv4 != NULL);

		// set  socket flag (clearing close on invalidate option)
        CFSocketSetSocketFlags(self->_listenerSocket_sd_ipv4,
							   CFSocketGetSocketFlags(self->_listenerSocket_sd_ipv4) &~ (CFOptionFlags)kCFSocketCloseOnInvalidate);
		
		// listen on port
		listen_on_port(fd, &boundPort,AF_INET);		

		// set runloop source
        runLoopSource = CFSocketCreateRunLoopSource(NULL, self->_listenerSocket_sd_ipv4, 0);
        assert(runLoopSource != NULL);

		// add the source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
        CFRelease(runLoopSource);
    }
	else
	{
		NSLog(@"there is an error annoucing service %x",errorType);
		//[self stopWithDNSServiceError:err];
		[self destroyBluetoothStack];
    }
}

-(void)destroyBluetoothStack
{
    if (self->_listenerSocket_sd_ipv4 != NULL)
	{
        CFSocketInvalidate(self->_listenerSocket_sd_ipv4);
        CFRelease(self->_listenerSocket_sd_ipv4);
        self->_listenerSocket_sd_ipv4 = NULL;
    }

    if (self->_sdServiceRef != NULL)
	{
        DNSServiceRefDeallocate(self->_sdServiceRef);
        self->_sdServiceRef = NULL;
    }
	
}

@end
