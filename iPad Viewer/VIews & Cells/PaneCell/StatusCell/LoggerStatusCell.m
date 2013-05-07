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


#import "LoggerStatusCell.h"
#import "LoggerConstModel.h"

@interface LoggerStatusCell()
@property (nonatomic, retain) NSDictionary *statusData;
@end

@implementation LoggerStatusCell
+ (CGFloat)rowHeight
{
	return 104.f;
}

-(void)finishConstruction
{
	[super finishConstruction];
	self.bluetoothLabel.text = NSLocalizedString(@"Bluetooth", nil);
	self.portLabel.text = NSLocalizedString(@"Port", nil);
}

-(void)dealloc
{
	self.statusData = nil;
	[super dealloc];
}


-(IBAction)bluetoothOnOff:(UISwitch *)aSwitch
{
	
}

-(IBAction)transportOnOff:(UISwitch *)aSwitch
{
	
}

-(void)configureForData:(id)dataObject
{
	self.statusData = dataObject;
	
	BOOL showSSLBadge = [[dataObject valueForKey:kTransportSecure] boolValue];
	BOOL transportReady = [[dataObject valueForKey:kTransportReady] boolValue];
	BOOL transportActivated = [[dataObject valueForKey:kTransportActivated] boolValue];
	BOOL openningFailed = [[dataObject valueForKey:kTransportFailed] boolValue];
	BOOL bluetoothUsed = [[dataObject valueForKey:kTransportBluetooth] boolValue];
	BOOL bonjourPublished  = [[dataObject valueForKey:kTransportBluetooth] boolValue];	
	NSString *infoString = [dataObject valueForKey:kTransportInfoString];
	NSString *statusString = [dataObject valueForKey:kTransportStatusString];
	

	[self.sslBadge setHidden:!showSSLBadge];
	self.portStatus.text = statusString;
	self.portInfo.text = infoString;
	
	[self.portOnOff setOn:transportActivated animated:NO];
	if(transportActivated)
	{
		[self.bluetoothOnOff setOn:bluetoothUsed animated:NO];
	}
	else
	{
		[self.bluetoothOnOff setOn:NO animated:NO];
	}
	
	[self.bluetoothOnOff setHidden:!bonjourPublished];
	[self.bluetoothLabel setHidden:!bonjourPublished];
	
	if(openningFailed)
	{
		[self.statusLED setImage:[UIImage imageNamed:@"NSLoggerResource.bundle/Icon/status_error.png"]];
	}
	else
	{
		if(transportReady)
		{
			[self.statusLED setImage:[UIImage imageNamed:@"NSLoggerResource.bundle/Icon/status_ready_connected.png"]];
		}
		else
		{
			[self.statusLED setImage:[UIImage imageNamed:@"NSLoggerResource.bundle/Icon/status_disconnected.png"]];
		}
	}
}
@end
