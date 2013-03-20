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

#import "ViewController.h"
#import "LoggerViewController.h"
#import "KGNoise.h"

@implementation ViewController
-(void)dealloc
{
	self.viewControllerData = nil;
	[super dealloc];
}

-(void)loadView
{
	CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
	CGRect viewFrame = (CGRect){CGPointZero,appFrame.size};
	
	KGNoiseRadialGradientView *noiseView = \
		[[KGNoiseRadialGradientView alloc]
		 initWithFrame:viewFrame];
    noiseView.backgroundColor = [UIColor colorWithRed:0.814 green:0.798 blue:0.747 alpha:1.000];
    noiseView.alternateBackgroundColor = [UIColor colorWithRed:1.000 green:0.986 blue:0.945 alpha:1.000];
    noiseView.noiseOpacity = 0.3;
	
    [self setView:noiseView];
	[noiseView release],noiseView = nil;
}

- (void)viewDidLoad
{
	self.viewControllerData = [NSMutableArray arrayWithCapacity:6];
	for(int i = 0; i < 6;i++)
	{
		LoggerViewController *vc = \
			[[LoggerViewController alloc]
			 initWithNibName:@"LoggerViewController"
			 bundle:[NSBundle mainBundle]];
		[self.viewControllerData addObject:vc];
		[vc release],vc = nil;
	}
   
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfControllerCardsInNoteView:(KLNoteViewController*) noteView
{
    return  [self.viewControllerData count];
}

- (UIViewController *)noteView:(KLNoteViewController*)noteView
viewControllerForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.viewControllerData objectAtIndex:indexPath.row];
}

-(void) noteViewController:(KLNoteViewController*) noteViewController
   didUpdateControllerCard:(KLControllerCard*)controllerCard
			toDisplayState:(KLControllerCardState) toState
		  fromDisplayState:(KLControllerCardState) fromState
{

}


@end
