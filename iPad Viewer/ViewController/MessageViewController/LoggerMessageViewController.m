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

#import <CoreData/CoreData.h>
#import "LoggerMessageViewController.h"

#import "LoggerCommon.h"
#import "LoggerMessageData.h"
#import "LoggerMessageCell.h"
#import "LoggerMarkerCell.h"
#import "LoggerClientInfoCell.h"

@interface LoggerMessageViewController ()
@property (nonatomic, retain) NSFetchedResultsController	*messageFetchResultController;
@end

@implementation LoggerMessageViewController
{
	NSFetchedResultsController	*_messageFetchResultController;
	UITableView					*_tableView;
}
@synthesize messageFetchResultController = _messageFetchResultController;
@synthesize tableView = _tableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self setDataManager:[LoggerDataManager sharedDataManager]];
	assert([self.dataManager messageDisplayContext] != nil);
	
	NSFetchRequest *request =\
		[[NSFetchRequest alloc] init];
	
	NSEntityDescription *entity =\
		[NSEntityDescription
		 entityForName:@"LoggerMessageData"
		 inManagedObjectContext:
		 [[self dataManager] messageDisplayContext]];
	
	[request setShouldRefreshRefetchedObjects:YES];
	[request setEntity:entity];
	[request setFetchBatchSize:20];
	//[request setFetchLimit:40];
	//[request setFetchOffset:0];
	
	//[request setPredicate:[NSPredicate predicateWithFormat:@"uniqueID <= 50"]];
	
	NSSortDescriptor *sortByTimestamp = \
		[[NSSortDescriptor alloc]
		 initWithKey:@"timestamp"
		 ascending:NO];

	NSSortDescriptor *sortBySequence = \
		[[NSSortDescriptor alloc]
		 initWithKey:@"sequence"
		 ascending:NO];
	
	[request setSortDescriptors:@[sortBySequence,sortByTimestamp]];
	
	[NSFetchedResultsController deleteCacheWithName:nil];
	
	NSFetchedResultsController *frc = \
		[[NSFetchedResultsController alloc]
		 initWithFetchRequest:request
		 managedObjectContext:[[self dataManager] messageDisplayContext]
		 sectionNameKeyPath:nil//@"uniqueID"
		 cacheName:nil];
#warning cache policy

	[frc setDelegate:self];
	[self setMessageFetchResultController:frc];
	
	NSError *error = nil;
	[frc performFetch:&error];
	
	[frc release],frc = nil;
	[sortBySequence release],sortBySequence = nil;
	[sortByTimestamp release],sortByTimestamp = nil;
	[entity release],entity = nil;
	[request release],request = nil;

}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	id <NSFetchedResultsSectionInfo> sectionInfo = [[_messageFetchResultController sections] objectAtIndex:0];
	NSArray *fetched = [_messageFetchResultController fetchedObjects];
	
	NSLog(@"total sections %d obj count %d fetched object %d"
		  ,[[_messageFetchResultController sections] count]
		  ,[sectionInfo numberOfObjects]
		  ,[fetched count]);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//------------------------------------------------------------------------------
#pragma mark - UITableViewDataSource Delegate Methods
//------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)aTableView
 numberOfRowsInSection:(NSInteger)aSection
{
    NSInteger numberOfRows = 0;
	
    if ([[self.messageFetchResultController sections] count] > 0)
	{
        id <NSFetchedResultsSectionInfo> sectionInfo = \
			[[self.messageFetchResultController sections] objectAtIndex:0];
        numberOfRows = [sectionInfo numberOfObjects];
    }
	
	MTLog(@"numberOfRowsInSection %d",numberOfRows);
	
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView
		 cellForRowAtIndexPath:(NSIndexPath *)anIndexPath
{
	LoggerMessageData *msg = \
		[self.messageFetchResultController objectAtIndexPath:anIndexPath];

	LoggerMessageCell *cell = nil;

	switch (msg.type)
	{
		case LOGMSG_TYPE_LOG:
		case LOGMSG_TYPE_BLOCKSTART:
		case LOGMSG_TYPE_BLOCKEND:
		{
			cell =
				[self.tableView
				 dequeueReusableCellWithIdentifier:kMessageCellReuseID];

			if(cell == nil)
			{
				cell = [[[LoggerMessageCell alloc]
						initWithPreConfig]
						autorelease];

				cell.hostTableView = self.tableView;
			}

			break;
		}
			
		case LOGMSG_TYPE_CLIENTINFO:
		case LOGMSG_TYPE_DISCONNECT:
		{
			cell =
				[self.tableView
				 dequeueReusableCellWithIdentifier:kClientInfoCellReuseID];

			if(cell == nil)
			{
				cell = [[[LoggerClientInfoCell alloc]
						initWithPreConfig]
						autorelease];
				
				cell.hostTableView = self.tableView;
			}

			break;
		}

		case LOGMSG_TYPE_MARK:
		{
			cell =
				[self.tableView
				 dequeueReusableCellWithIdentifier:kMarkerCellReuseID];

			if(cell == nil)
			{
				cell = [[[LoggerMarkerCell alloc]
						initWithPreConfig]
						autorelease];

				cell.hostTableView = self.tableView;
			}
			
			break;
		}
	}

	[cell setupForIndexpath:anIndexPath messageData:msg];

	return cell;
}

#ifdef TEST_CELL_INDEXPATH
- (void)tableView:(UITableView *)aTableView
  willDisplayCell:(UITableViewCell *)aCell
forRowAtIndexPath:(NSIndexPath *)anIndexPath
{
	LoggerMessageData *msg = \
		[self.messageFetchResultController objectAtIndexPath:anIndexPath];

	[(LoggerMessageCell *)aCell willDisplayForIndexPath:anIndexPath messageData:msg];
}
#endif

//------------------------------------------------------------------------------
#pragma mark - UITableViewDelegate Delegate Methods
//------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)aTableView
heightForRowAtIndexPath:(NSIndexPath *)anIndexPath
{
	LoggerMessageData *data = [self.messageFetchResultController objectAtIndexPath:anIndexPath];
	return [data portraitHeight];
}

- (CGFloat)tableView:(UITableView *)aTableView
heightForHeaderInSection:(NSInteger)aSection
{
	return 0.f;
}

- (CGFloat)tableView:(UITableView *)aTableView
heightForFooterInSection:(NSInteger)aSection
{
	return 0.f;
}

//------------------------------------------------------------------------------
#pragma mark - NSFetchedResultController Delegate
//------------------------------------------------------------------------------

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller;
{
	[self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)aController
   didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)anIndexPath
	 forChangeType:(NSFetchedResultsChangeType)aType
	  newIndexPath:(NSIndexPath *)aNewIndexPath
{
	UITableView *tableView = self.tableView;
	
	switch(aType) {
		case NSFetchedResultsChangeInsert:
			[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:aNewIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:anIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;

		case NSFetchedResultsChangeUpdate:
		{
			LoggerMessageCell *cell =
				(LoggerMessageCell *)[self.tableView cellForRowAtIndexPath:anIndexPath];
			[cell setupForIndexpath:anIndexPath messageData:(LoggerMessageData *)anObject];
			break;
		}
		case NSFetchedResultsChangeMove:
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:anIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:aNewIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
	}

}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex
	 forChangeType:(NSFetchedResultsChangeType)type
{
}

#if 0
- (NSString *)controller:(NSFetchedResultsController *)controller
sectionIndexTitleForSectionName:(NSString *)sectionName
{

}
#endif

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	[self.tableView endUpdates];
}

@end
