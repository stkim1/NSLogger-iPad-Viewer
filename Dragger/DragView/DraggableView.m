//
//  DraggableView.m
//  Dragger
//
//  Created by Almighty Kim on 3/27/13.
//  Copyright (c) 2013 Colorful Glue. All rights reserved.
//

#import "DraggableView.h"

@interface DraggableView()<UIGestureRecognizerDelegate>
-(void)finishConstruction;
-(void)longPressed:(UILongPressGestureRecognizer *)aLongPressGesture;
-(void)beingDragged:(UIPanGestureRecognizer *)aPanGesture;
@end

//max home comming anim period
#define HOME_COMING_PERIOD 0.4f

//diagonal dist
#define MAX_DIST_FROM_HOME 1280.f

static
CGFloat _calc_distance_to_home(CGPoint current, CGPoint home)
{
	CGFloat dist_x = current.x - home.x;
	CGFloat dist_y = current.y - home.y;
	return sqrtf(dist_x*dist_x + dist_y * dist_y);
}


@implementation DraggableView
{
	CGPoint _homePoint;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
		[self finishConstruction];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if(self)
	{
		[self finishConstruction];
	}
	return self;
}

-(void)finishConstruction
{
	// backup home point
	_homePoint = self.center;
	
#if 0
	UILongPressGestureRecognizer *longPress =\
		[[UILongPressGestureRecognizer alloc] init];
	longPress.minimumPressDuration = 0.5f;
	longPress.delegate = self;
	[longPress addTarget:self action:@selector(longPressed:)];
	[self addGestureRecognizer:longPress];
	[longPress release],longPress = nil;
#endif
	UIPanGestureRecognizer *panning = \
		[[UIPanGestureRecognizer alloc] init];
	panning.maximumNumberOfTouches = 1;
	panning.delegate = nil;
	[panning addTarget:self action:@selector(beingDragged:)];
	[self addGestureRecognizer:panning];
	[panning release],panning = nil;
}

-(void)dealloc
{
	[super dealloc];
}

#if 0
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
#endif

//------------------------------------------------------------------------------
#pragma mark - UIGestureRecognizerDelegate
//------------------------------------------------------------------------------
-(void)longPressed:(UILongPressGestureRecognizer *)aLongPressGesture
{
	NSLog(@"long pressed %@",self);
}

-(void)beingDragged:(UIPanGestureRecognizer *)aPanGesture
{
	UIGestureRecognizerState dragState = [aPanGesture state];
	switch (dragState)
	{
        case UIGestureRecognizerStateBegan:
			
            break;

        case UIGestureRecognizerStateChanged:{
			CGPoint translation = [aPanGesture translationInView:[self superview]];
			CGPoint center = self.center;
			self.center = (CGPoint){(center.x + translation.x),(center.y + translation.y)};
			[aPanGesture setTranslation:CGPointZero inView:[self superview]];
            break;
		}
        case UIGestureRecognizerStateEnded:
		default:{
			// check if this view made to target frame
			
			
			//[self hitTest:<#(CGPoint)#> withEvent:<#(UIEvent *)#>]
			
			// if not then...

			__const CGPoint lastCenter = self.center;
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				CGFloat distance = _calc_distance_to_home(lastCenter, _homePoint);
				CGFloat homeBoundPeriod = HOME_COMING_PERIOD * (1 - (distance /MAX_DIST_FROM_HOME));
				[UIView
				 animateWithDuration:homeBoundPeriod
				 delay:0
				 options:(UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction)
				 animations:^{
					 self.center = _homePoint;
				 }
				 completion:^(BOOL finished) {

				 }];
				
			}];

            
			break;
		}
    }
}


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
	return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
	   shouldReceiveTouch:(UITouch *)touch
{
	return YES;
}

@end
