//
//  BaseCell.m
//
//  Created by Matt Gallagher on 2010/01/22.
//  Copyright 2010 Matt Gallagher. All rights reserved.
//
//  This software is provided 'as-is', without any express or implied
//  warranty. In no event will the authors be held liable for any damages
//  arising from the use of this software. Permission is granted to anyone to
//  use this software for any purpose, including commercial applications, and to
//  alter it and redistribute it freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//  3. This notice may not be removed or altered from any source
//     distribution.
//

#import "LoggerBaseCell.h"

@implementation LoggerBaseCell
+ (NSString *)reuseIdentifier
{
	return NSStringFromClass([self class]);
}

+ (NSString *)nibName
{
	return NSStringFromClass([self class]);
}

+ (CGFloat)rowHeight
{
	return 44.f;
}

- (id)init
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	NSArray *nibContent = \
		[[NSBundle mainBundle]
		loadNibNamed:[[self class] nibName]
		owner:self
		options:nil];
	
	for (id currentObject in nibContent)
	{
		if ([currentObject isKindOfClass:[self class]]){
			[self autorelease];
			self = [currentObject retain];
			break;
		}
	}

	[pool release];
	
	if(self)
	{
		[self finishConstruction];
	}
	
	return self;
}

- (void)finishConstruction
{
}

- (void)dealloc
{
	self.delegate = nil;
	[super dealloc];
}

- (void)configureForData:(id)dataObject
{
}
@end
