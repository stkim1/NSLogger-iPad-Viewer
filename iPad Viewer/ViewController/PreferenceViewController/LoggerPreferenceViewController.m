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

#import "LoggerPreferenceViewController.h"

#import "LoggerStatusPane.h"
#import "LoggerGeneralPane.h"
#import "LoggerNetworkPane.h"

static NSString * const kPreferenceTitle = @"Preference";
static NSString * const kPreferenceCellID = @"pref_item_cell";
static NSString * const kItemTitle = @"item_title";
static NSString * const kItemClass = @"item_class";

@interface LoggerPreferenceViewController ()
@property (nonatomic, retain) NSArray *preferenceItems;
-(void)switchTitle:(NSString *)aTitle;
-(void)switchPane:(NSString *)aPaneName;
@end

@implementation LoggerPreferenceViewController{
	NSUInteger		_prefSectionIndex;
	NSUInteger		_prefRowIndex;
}
-(void)completeInstanceCreation
{
	[super completeInstanceCreation];

	if([[NSBundle mainBundle]
		URLForResource:@"NSLoggerResource.bundle/LoggerPreferenceItems"
		withExtension:@"plist"])
	{
		NSArray *prefItems = \
			[NSArray arrayWithContentsOfFile:
			 [[NSBundle mainBundle]
			  pathForResource:@"NSLoggerResource.bundle/LoggerPreferenceItems"
			  ofType:@"plist"]];

		if(prefItems != nil)
		{
			self.preferenceItems = prefItems;

		}
	}
}

-(void)finishViewConstruction
{
	[super finishViewConstruction];
	[self.navigationController.navigationBar setFrame:(CGRect){CGPointZero,{self.view.frame.size.width,79.f}}];
	
	NSIndexPath *thePath = [NSIndexPath indexPathForRow:_prefRowIndex inSection:_prefSectionIndex];
	
	[self.preferenceTable
	 selectRowAtIndexPath:thePath
	 animated:NO
	 scrollPosition:UITableViewScrollPositionNone];

	[self tableView:nil didSelectRowAtIndexPath:thePath];
}

-(void)startViewDestruction
{
	[super startViewDestruction];

	self.preferenceTable.delegate = nil;
	self.preferenceTable.dataSource = nil;
	self.preferenceTable = nil;
	
	for(UIViewController *vc in [self childViewControllers])
	{
		[vc.view removeFromSuperview];
		[vc removeFromParentViewController];
	}
}

-(void)beginInstanceDestruction
{
	[super beginInstanceDestruction];
	self.preferenceItems = nil;
}


//------------------------------------------------------------------------------
#pragma mark - Instance Methods
//------------------------------------------------------------------------------
-(void)switchTitle:(NSString *)aTitle
{
	NSString *localizedTitle = \
		[NSString stringWithFormat:@"%@ %@"
		 ,NSLocalizedString(kPreferenceTitle, nil)
		 ,NSLocalizedString(aTitle, nil)];

	self.navigationItem.title = localizedTitle;
}

-(void)switchPane:(NSString *)aPaneName
{
	for(UIViewController *vc in [self childViewControllers])
	{
		[vc.view removeFromSuperview];
		[vc removeFromParentViewController];
	}
	
	UIViewController *aPane = (UIViewController *)[NSClassFromString(aPaneName) new];
	[self addChildViewController:aPane];
	[aPane didMoveToParentViewController:self];
	[self.view addSubview:aPane.view];
	CGRect frame = [[aPane view] frame];
	[[aPane view] setFrame:(CGRect){{321.f,35.f},frame.size}];
	[aPane release],aPane = nil;
}



//------------------------------------------------------------------------------
#pragma mark - UITableViewDataSource Delegate Methods
//------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [self.preferenceItems count];
}

- (NSInteger)tableView:(UITableView *)aTableView
 numberOfRowsInSection:(NSInteger)aSection
{
	return [[self.preferenceItems objectAtIndex:aSection] count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView
		 cellForRowAtIndexPath:(NSIndexPath *)anIndexPath
{
	UITableViewCell *cell = [aTableView
							 dequeueReusableCellWithIdentifier:kPreferenceCellID];
	if(cell == nil)
	{
		cell = [[UITableViewCell alloc]
				initWithStyle:UITableViewCellStyleDefault
				reuseIdentifier:kPreferenceCellID];
	}
	
	cell.textLabel.text = \
		[[[self.preferenceItems objectAtIndex:[anIndexPath section]]
		  objectAtIndex:[anIndexPath row]]
		 valueForKey:kItemTitle];
	
	return cell;
}

//------------------------------------------------------------------------------
#pragma mark - UITableViewDelegate Delegate Methods
//------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)aTableView
heightForRowAtIndexPath:(NSIndexPath *)anIndexPath
{
	return 44.f;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section
{
	return 0.f;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForFooterInSection:(NSInteger)section
{
	// This will create a "invisible" footer
	return 0.f;
}

- (void)tableView:(UITableView *)aTableView
didSelectRowAtIndexPath:(NSIndexPath *)anIndexPath
{
	NSString *paneName = \
		[[[self.preferenceItems objectAtIndex:_prefSectionIndex]
		  objectAtIndex:_prefRowIndex]
		 valueForKey:kItemTitle];
	
	[self switchTitle:paneName];
	
	NSString *paneClass = \
		[[[self.preferenceItems objectAtIndex:[anIndexPath section]]
		  objectAtIndex:[anIndexPath row]]
		 valueForKey:kItemClass];

	[self switchPane:paneClass];
	
	// record selection
	_prefSectionIndex = [anIndexPath section];
	_prefRowIndex = [anIndexPath row];
}

@end
