//
//  ViewController.m
//  LoggerStorage
//
//  Created by Almighty Kim on 12/16/12.
//  Copyright (c) 2012 Colorful Glue. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
	
}

-(IBAction)delete:(id)sender
{
	AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	[delegate deletePath];
}


@end
