//
//  LoggerViewController.m
//  UIProtoWork
//
//  Created by Almighty Kim on 3/17/13.
//  Copyright (c) 2013 Colorful Glue. All rights reserved.
//

#import "LoggerViewController.h"
#import "KGNoise.h"

@implementation LoggerViewController

-(void)loadView
{
	[super loadView];

	CGRect noiseNavbarViewRect = (CGRect){CGPointZero,{self.view.bounds.size.width,48.f}};
    KGNoiseLinearGradientView *noiseNavbarView = [[KGNoiseLinearGradientView alloc] initWithFrame:noiseNavbarViewRect];
    noiseNavbarView.backgroundColor = [UIColor colorWithRed:0.307 green:0.455 blue:0.909 alpha:1.000];
    noiseNavbarView.alternateBackgroundColor = [UIColor colorWithRed:0.363 green:0.700 blue:0.909 alpha:1.000];
    noiseNavbarView.noiseBlendMode = kCGBlendModeMultiply;
    noiseNavbarView.noiseOpacity = 0.08;
	[self.navigationController.navigationBar addSubview:noiseNavbarView];
	[noiseNavbarView release],noiseNavbarView = nil;

	[self.view setBackgroundColor:[UIColor whiteColor]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
