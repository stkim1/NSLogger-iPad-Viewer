//
//  DraggableCell.m
//  Dragger
//
//  Created by Almighty Kim on 3/28/13.
//  Copyright (c) 2013 Colorful Glue. All rights reserved.
//

#import "DraggableCell.h"

@implementation DraggableCell
{
	CGPoint touchStart;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setAlpha:(CGFloat)alpha
{
	[super setAlpha:1.f];
}

-(void)setHidden:(BOOL)hidden
{
	[super setHidden:NO];
}

//------------------------------------------------------------------------------
#pragma mark - Touch Events For Dragging
//------------------------------------------------------------------------------
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    touchStart = [touch locationInView:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint touchPoint = [[touches anyObject] locationInView:self];
	CGPoint newCenter = CGPointMake(self.center.x + touchPoint.x - touchStart.x
									, self.center.y + touchPoint.y - touchStart.y);
    self.center = newCenter;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
}


@end
