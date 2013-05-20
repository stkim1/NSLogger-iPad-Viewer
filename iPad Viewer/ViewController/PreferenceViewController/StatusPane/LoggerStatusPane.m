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

#import "LoggerStatusPane.h"
#import "LoggerTransportManager.h"
#import "LoggerConstModel.h"
#import "LoggerStatusCell.h"

@interface LoggerStatusPane ()
@property (nonatomic, retain) NSMutableArray *statusValues;
-(void)updateStatus:(NSNotification *)aNotification;
@end

@implementation LoggerStatusPane

-(void)completeInstanceCreation
{
	[super completeInstanceCreation];
	
	self.statusValues = \
		[NSMutableArray arrayWithObjects:
			@{kTransportTag:[NSNumber numberWithInt:0]
			,kTransportSecure:[NSNumber numberWithBool:TRUE]
			,kTransportReady:[NSNumber numberWithBool:FALSE]
			,kTransportActivated:[NSNumber numberWithBool:FALSE]
			,kTransportFailed:[NSNumber numberWithBool:FALSE]
			,kTransportBluetooth:[NSNumber numberWithBool:TRUE]
			,kTransportBonjour:[NSNumber numberWithBool:TRUE]
			,kTransportInfoString:@"(Bonjour, SSL)"
			,kTransportStatusString:@"Opening port..."}
		 
			,@{kTransportTag:[NSNumber numberWithInt:1]
			,kTransportSecure:[NSNumber numberWithBool:FALSE]
			,kTransportReady:[NSNumber numberWithBool:FALSE]
			,kTransportActivated:[NSNumber numberWithBool:FALSE]
			,kTransportFailed:[NSNumber numberWithBool:FALSE]
			,kTransportBluetooth:[NSNumber numberWithBool:TRUE]
			,kTransportBonjour:[NSNumber numberWithBool:TRUE]
			,kTransportInfoString:@"(Bonjour)"
			,kTransportStatusString:@"Opening port..."}
 
			,@{kTransportTag:[NSNumber numberWithInt:2]
			,kTransportSecure:[NSNumber numberWithBool:TRUE]
			,kTransportReady:[NSNumber numberWithBool:FALSE]
			,kTransportActivated:[NSNumber numberWithBool:FALSE]
			,kTransportFailed:[NSNumber numberWithBool:FALSE]
			,kTransportBluetooth:[NSNumber numberWithBool:NO]
			,kTransportBonjour:[NSNumber numberWithBool:NO]
			,kTransportInfoString:@"(Direct TCP)"
			,kTransportStatusString:@"Opening port..."}
	 , nil];
	
	
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(updateStatus:)
	 name:kShowTransportStatusNotification
	 object:[LoggerTransportManager sharedTransportManager]];
}

-(void)beginInstanceDestruction
{
	[super beginInstanceDestruction];
	self.statusValues = nil;
	
	[[NSNotificationCenter defaultCenter]
	 removeObserver:self
	 name:kShowTransportStatusNotification
	 object:[LoggerTransportManager sharedTransportManager]];
}

-(void)updateStatus:(NSNotification *)aNotification
{
	NSDictionary *portStatus = [aNotification userInfo];	
	int32_t portTag = [[portStatus valueForKey:kTransportTag] intValue];
	[self.statusValues replaceObjectAtIndex:portTag withObject:portStatus];
	[self.itemTable
	 reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:portTag inSection:0]]
	 withRowAnimation:UITableViewRowAnimationNone];
}

//------------------------------------------------------------------------------
#pragma mark - UITableViewDelegate Delegate Methods
//------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView
 numberOfRowsInSection:(NSInteger)aSection
{
	return [self.statusValues count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView
		 cellForRowAtIndexPath:(NSIndexPath *)anIndexPath
{
	LoggerStatusCell *cell = \
		[aTableView
		 dequeueReusableCellWithIdentifier:[LoggerStatusCell reuseIdentifier]];
	if(cell == nil)
	{
		cell = [[LoggerStatusCell new] autorelease];
		cell.delegate = self;
	}

	[cell configureForData:[self.statusValues objectAtIndex:[anIndexPath row]]];
	return cell;
}

//------------------------------------------------------------------------------
#pragma mark - UITableViewDelegate Delegate Methods
//------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)aTableView
heightForRowAtIndexPath:(NSIndexPath *)anIndexPath
{
	return [LoggerStatusCell rowHeight];
}

@end
