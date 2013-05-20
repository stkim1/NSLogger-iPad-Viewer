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
#import "LoggerNetworkPane.h"
#import "LoggerNetworkBonjourCell.h"
#import "LoggerNetworkDirectPortCell.h"

@interface LoggerNetworkPane ()

@end

@implementation LoggerNetworkPane
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
	return 2;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView
		 cellForRowAtIndexPath:(NSIndexPath *)anIndexPath
{
	LoggerBaseCell *cell = nil;
	
	switch ([anIndexPath row])
	{
		case 0:{
			cell = [aTableView dequeueReusableCellWithIdentifier:[LoggerNetworkBonjourCell reuseIdentifier]];
			if(cell == nil)
			{
				cell = [[LoggerNetworkBonjourCell new] autorelease];
				cell.delegate = self;
			}
			break;
		}
		default:{
			cell = [aTableView dequeueReusableCellWithIdentifier:[LoggerNetworkDirectPortCell reuseIdentifier]];
			if(cell == nil)
			{
				cell = [[LoggerNetworkDirectPortCell new] autorelease];
				cell.delegate = self;
			}
			break;
		}
	}
	 	
	return cell;
}

//------------------------------------------------------------------------------
#pragma mark - UITableViewDelegate Delegate Methods
//------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)aTableView
heightForRowAtIndexPath:(NSIndexPath *)anIndexPath
{
	if ([anIndexPath row] == 0)
	{
		return [LoggerNetworkBonjourCell rowHeight];
	}

	return [LoggerNetworkDirectPortCell rowHeight];
}

@end
