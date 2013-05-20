//
//  ViewController.m
//  Dragger
//
//  Created by Almighty Kim on 3/27/13.
//  Copyright (c) 2013 Colorful Glue. All rights reserved.
//

#import "ViewController.h"
#import "DraggableCell.h"

@interface ViewController ()

@end

@implementation ViewController
{
	NSMutableArray *_filters;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	_filters = [[NSMutableArray alloc] initWithCapacity:6];
	
	

	
	for(int i = 0; i< 6; i++)
	{
		[_filters addObject:[NSString stringWithFormat:@"%d filter",i]];
	}
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_filters count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
		 cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"DragCell";

    DraggableCell *cell = [self.filterList dequeueReusableCellWithIdentifier:CellIdentifier];
	
    if (!cell)
	{
        cell = \
			[[[DraggableCell alloc]
			  initWithStyle:UITableViewCellStyleDefault
			  reuseIdentifier:CellIdentifier]
			 autorelease];

        cell.showsReorderControl = YES;
    }

    cell.textLabel.text = [_filters objectAtIndex:indexPath.row];
    return cell;
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(void)tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath
	 toIndexPath:(NSIndexPath *)destinationIndexPath
{
	[_filters exchangeObjectAtIndex:sourceIndexPath.row withObjectAtIndex:destinationIndexPath.row];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView
		   editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}


- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSLog(@"editing style %d index path %d",editingStyle, [indexPath row]);
	
	return;

	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
        [self.filterList deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}


- (IBAction)doSomething:(id)sender {

	if(self.filterList.isEditing)
	{
		[self.filterList setEditing:NO animated:YES];
	}
	else
	{
		[self.filterList setEditing:YES animated:YES];
	}
}



-(IBAction)popCell:(id)sender
{
	
	
	
	
	
	
	
	return;
	NSIndexPath *target = [NSIndexPath indexPathForRow:2 inSection:0];

	UITableViewCell *cell = [self.filterList cellForRowAtIndexPath:target];
	[cell retain];
	[cell removeFromSuperview];

#if 0
	[_filters removeObjectAtIndex:2];
	[self.filterList deleteRowsAtIndexPaths:@[target] withRowAnimation:UITableViewRowAnimationNone];
#endif
	

	[self.view addSubview:cell];
	[cell release];

	for(UIView *v in self.view.subviews)
	{
		NSLog(@"v : %@",[v description]);
	}
}



@end
