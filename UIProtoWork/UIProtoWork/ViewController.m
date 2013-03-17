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
 * materials  provided with  the distribution.  Neither the  name of  Sung-Ta
 * ek kim nor the names of its contributors may be used to endorse or promote
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

#import "ViewController.h"

@implementation ViewController
-(void)dealloc
{
	self.viewControllerData = nil;
	[super dealloc];
}

- (void)viewDidLoad
{
	self.viewControllerData = [NSMutableArray arrayWithCapacity:6];
	
	for(int i = 0; i < 6;i++)
	{
		UIViewController *vc = [UIViewController new];
		[self.viewControllerData addObject:vc];
		[vc release];
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
