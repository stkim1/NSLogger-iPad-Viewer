/*
 * Copyright (c) 2012 Kieran Lafferty
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */

#import "KLNoteViewController.h"
#import <QuartzCore/QuartzCore.h>

//Layout properties
#define kDefaultMinimizedScalingFactor 0.98     //Amount to shrink each card from the previous one
#define kDefaultMaximizedScalingFactor 1.00     //Maximum a card can be scaled to
#define kDefaultNavigationBarOverlap 0.90       //Defines vertical overlap of each navigation toolbar. Slight hack that prevents rounding errors from showing the whitespace between navigation toolbars. Can be customized if require more/less packing of navigation toolbars

//Animation properties
#define kDefaultAnimationDuration 0.3           //Amount of time for the animations to occur
#define kDefaultReloadHideAnimationDuration 0.4
#define kDefaultReloadShowAnimationDuration 0.6

//Position for the stack of navigation controllers to originate at
#define kDefaultVerticalOrigin 100              //Vertical origin of the controller card stack. Making this value larger/smaller will make the card shift down/up.

//Corner radius properties
#define kDefaultCornerRadius 5.0

//Shadow Properties - Note : Disabling shadows greatly improves performance and fluidity of animations
#define kDefaultShadowEnabled YES
#define kDefaultShadowColor [UIColor blackColor]
#define kDefaultShadowOffset CGSizeMake(0, -5)
#define kDefaultShadowRadius kDefaultCornerRadius
#define kDefaultShadowOpacity 0.60

//Gesture properties
#define kDefaultMinimumPressDuration 0.2

//------------------------------------------------------------------------------
#pragma mark - KLNoteViewController
//------------------------------------------------------------------------------
@interface KLNoteViewController ()
- (void)configureDefaultSettings;

//Drawing information for the navigation controllers
- (CGFloat)defaultVerticalOriginForControllerCard:(KLControllerCard *)controllerCard atIndex:(NSInteger)index;

- (CGFloat)scalingFactorForIndex:(NSInteger)index;
@end

@implementation KLNoteViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (!self)
	{
		return nil;
	}
	[self configureDefaultSettings];
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (!self)
	{
		return nil;
	}
	[self configureDefaultSettings];
	return self;
}

-(void)dealloc
{
	self.cardShadowColor = nil;
	self.controllerCards = nil;
	
	[super dealloc];
}



- (void)configureDefaultSettings
{
	self.cardNavigationBarClass          = [UINavigationBar class];

	self.cardMinimizedScalingFactor      = kDefaultMinimizedScalingFactor;
	self.cardMaximizedScalingFactor      = kDefaultMaximizedScalingFactor;
	self.cardNavigationBarOverlap        = kDefaultNavigationBarOverlap;

	self.cardAnimationDuration           = kDefaultAnimationDuration;
	self.cardReloadHideAnimationDuration = kDefaultReloadHideAnimationDuration;
	self.cardReloadShowAnimationDuration = kDefaultReloadShowAnimationDuration;

	self.cardVerticalOrigin              = kDefaultVerticalOrigin;

	self.cardCornerRadius                = kDefaultCornerRadius;

	self.cardShadowEnabled               = kDefaultShadowEnabled;
	self.cardShadowColor                 = kDefaultShadowColor;
	self.cardShadowOffset                = kDefaultShadowOffset;
	self.cardShadowRadius                = kDefaultShadowRadius;
	self.cardShadowOpacity               = kDefaultShadowOpacity;

	self.cardPanGestureScope             = KLControllerCardPanGestureScopeNavigationBar;
	self.cardEnablePressGesture          = YES;
	self.cardMinimumPressDuration        = kDefaultMinimumPressDuration;

	self.cardAutoresizingMask            = (UIViewAutoresizingFlexibleBottomMargin |
	                                        UIViewAutoresizingFlexibleHeight |
	                                        UIViewAutoresizingFlexibleLeftMargin |
	                                        UIViewAutoresizingFlexibleRightMargin |
	                                        UIViewAutoresizingFlexibleTopMargin |
	                                        UIViewAutoresizingFlexibleWidth);
}

- (void)viewDidLoad
{

	//Populate the navigation controllers to the controller stack
	[self reloadData];

	[super viewDidLoad];

	// Do any additional setup after loading the view.
	[self reloadInputViews];

}

#pragma Drawing Methods - Used to position and present the navigation controllers on screen

- (CGFloat)defaultVerticalOriginForControllerCard:(KLControllerCard *)controllerCard
										  atIndex:(NSInteger)index
{
	//Sum up the shrunken size of each of the cards appearing before the current index
	CGFloat originOffset = 0;
	for (int i = 0; i < index; i++) {
		CGFloat scalingFactor = [self scalingFactorForIndex:i];
//        NSLog(@"%@", controllerCard.navigationController.navigationBar);
		originOffset += scalingFactor * controllerCard.navigationController.navigationBar.frame.size.height * self.cardNavigationBarOverlap;
	}

	//Position should start at self.cardVerticalOrigin and move down by size of nav toolbar for each additional nav controller
	return self.cardVerticalOrigin + originOffset;
}

- (CGFloat)scalingFactorForIndex:(NSInteger)index
{
	//Items should get progressively smaller based on their index in the navigation controller array
	return powf(self.cardMinimizedScalingFactor, (totalCards - index));
}

- (void)reloadData
{
	//Get the number of navigation  controllers to expect
	totalCards = [self numberOfControllerCardsInNoteView:self];

	//For each expected controller grab from the instantiating class and populate into local controller stack
	NSMutableArray *navigationControllers = [[NSMutableArray alloc] initWithCapacity:totalCards];
	for (NSInteger count = 0; count < totalCards; count++)
	{
		UIViewController *viewController =\
			[self
			 noteView:self
			 viewControllerForRowAtIndexPath:
				[NSIndexPath indexPathForRow:count inSection:0]];

		UINavigationController *navigationController = \
			[[UINavigationController alloc]
			 initWithNavigationBarClass:self.cardNavigationBarClass
			 toolbarClass:[UIToolbar class]];
		[navigationController pushViewController:viewController animated:NO];

		KLControllerCard *noteContainer = \
			[[KLControllerCard alloc]
			 initWithNoteViewController:self
			 navigationController:navigationController
			 index:count];
		
		[noteContainer setDelegate:self];
		[navigationControllers addObject:noteContainer];

		//Add the top view controller as a child view controller
		[self addChildViewController:navigationController];

		//As child controller will call the delegate methods for UIViewController
		[navigationController didMoveToParentViewController:self];

		//Add as child view controllers
	}

	self.controllerCards = [NSArray arrayWithArray:navigationControllers];
}

- (void)reloadDataAnimated:(BOOL)animated
{
	if (animated) {
		[UIView
		 animateWithDuration:self.cardReloadHideAnimationDuration
		 animations:^{
			 for (KLControllerCard * card in self.controllerCards)
			 {
				 [card setState:KLControllerCardStateHiddenBottom animated:NO];
			 }
		 } completion:^(BOOL finished) {
			 [self reloadData];
			 [self reloadInputViews];
			 for (KLControllerCard * card in self.controllerCards)
			 {
				 [card setState:KLControllerCardStateHiddenBottom animated:NO];
			 }
			 
			 [UIView
			  animateWithDuration:self.cardReloadShowAnimationDuration
			  animations:^{
				 for (KLControllerCard * card in self.controllerCards)
				 {
					 [card setState:KLControllerCardStateDefault animated:NO];
				 }
			  }];
		 }];
	}
	else
	{
		[self reloadData];
	}
}

- (void)reloadInputViews
{
	[super reloadInputViews];

	//First remove all of the navigation controllers from the view to avoid redrawing over top of views
	[self removeNavigationContainersFromSuperView];

	//Add the navigation controllers to the view
	for (KLControllerCard *container in self.controllerCards)
	{
		[self.view addSubview:container];
	}
}

#pragma mark - Manage KLControllerCard helpers

- (void)removeNavigationContainersFromSuperView
{
	for (KLControllerCard *navigationContainer in self.controllerCards)
	{
		[navigationContainer.navigationController willMoveToParentViewController:nil]; // 1
		[navigationContainer removeFromSuperview];    // 2
	}
}

- (NSIndexPath *)indexPathForControllerCard:(KLControllerCard *)navigationContainer
{
	NSInteger rowNumber = [self.controllerCards indexOfObject:navigationContainer];
	return [NSIndexPath indexPathForRow:rowNumber inSection:0];
}

- (NSArray *)controllerCardAboveCard:(KLControllerCard *)card
{
	NSInteger index = [self.controllerCards indexOfObject:card];
	return
		[self.controllerCards
		 filteredArrayUsingPredicate:
			[NSPredicate predicateWithBlock:^BOOL (KLControllerCard * controllerCard, NSDictionary * bindings) {
				NSInteger currentIndex = [self.controllerCards indexOfObject:controllerCard];
				//Only return cards with an index less than the one being compared to
				return index > currentIndex;
		}]];
}

- (NSArray *)controllerCardBelowCard:(KLControllerCard *)card
{
	NSInteger index = [self.controllerCards indexOfObject:card];
	return
		[self.controllerCards
		 filteredArrayUsingPredicate:
			[NSPredicate predicateWithBlock:^BOOL (KLControllerCard * controllerCard, NSDictionary * bindings) {
				NSInteger currentIndex = [self.controllerCards indexOfObject:controllerCard];
				//Only return cards with an index greater than the one being compared to
				return index < currentIndex;
		}]];
}

#pragma mark - KLNoteViewController Data Source methods

//If the controller is subclassed it will allow these values to be grabbed by the subclass. If not sublclassed it will grab from the assigned datasource.
- (NSInteger)numberOfControllerCardsInNoteView:(KLNoteViewController *)noteView {
	return [self.dataSource numberOfControllerCardsInNoteView:self];
}

- (UIViewController *)noteView:(KLNoteViewController *)noteView viewControllerForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [self.dataSource noteView:noteView viewControllerForRowAtIndexPath:indexPath];
}

#pragma mark - Delegate implementation for KLControllerCard

- (void)controllerCard:(KLControllerCard *)controllerCard didChangeToDisplayState:(KLControllerCardState)toState fromDisplayState:(KLControllerCardState)fromState {

	if (fromState == KLControllerCardStateDefault && toState == KLControllerCardStateFullScreen) {

		//For all cards above the current card move them
		for (KLControllerCard *currentCard in [self controllerCardAboveCard : controllerCard]) {
			[currentCard setState:KLControllerCardStateHiddenTop animated:YES];
		}
		for (KLControllerCard *currentCard in [self controllerCardBelowCard : controllerCard]) {
			[currentCard setState:KLControllerCardStateHiddenBottom animated:YES];
		}
	}
	else if (fromState == KLControllerCardStateFullScreen && toState == KLControllerCardStateDefault) {
		//For all cards above the current card move them back to default state
		for (KLControllerCard *currentCard in [self controllerCardAboveCard : controllerCard]) {
			[currentCard setState:KLControllerCardStateDefault animated:YES];
		}
		//For all cards below the current card move them back to default state
		for (KLControllerCard *currentCard in [self controllerCardBelowCard : controllerCard]) {
			[currentCard setState:KLControllerCardStateHiddenBottom animated:NO];
			[currentCard setState:KLControllerCardStateDefault animated:YES];
		}
	}
	else if (fromState == KLControllerCardStateDefault && toState == KLControllerCardStateDefault) {
		//If the current state is default and the user does not travel far enough to kick into a new state, then  return all cells back to their default state
		for (KLControllerCard *cardBelow in [self controllerCardBelowCard : controllerCard]) {
			[cardBelow setState:KLControllerCardStateDefault animated:YES];
		}
	}

	//Notify the delegate of the change
	[self noteViewController:self
	 didUpdateControllerCard:controllerCard
	          toDisplayState:toState
	        fromDisplayState:fromState];

}

- (void)noteViewController:(KLNoteViewController *)noteViewController didUpdateControllerCard:(KLControllerCard *)controllerCard toDisplayState:(KLControllerCardState)toState fromDisplayState:(KLControllerCardState)fromState {
	if ([self.delegate respondsToSelector:@selector(noteViewController:didUpdateControllerCard:toDisplayState:fromDisplayState:)]) {
		[self.delegate noteViewController:self
		          didUpdateControllerCard:controllerCard
		                   toDisplayState:toState
		                 fromDisplayState:fromState];
	}
}

- (void)controllerCard:(KLControllerCard *)controllerCard didUpdatePanPercentage:(CGFloat)percentage {
	if (controllerCard.state == KLControllerCardStateFullScreen) {
		for (KLControllerCard *currentCard in [self controllerCardAboveCard : controllerCard]) {
			CGFloat yCoordinate = (CGFloat) currentCard.origin.y * [controllerCard percentageDistanceTravelled];
			[currentCard setYCoordinate:yCoordinate];
		}
	}
	else if (controllerCard.state == KLControllerCardStateDefault) {
		for (KLControllerCard *currentCard in [self controllerCardBelowCard : controllerCard]) {
			CGFloat deltaDistance = controllerCard.frame.origin.y - controllerCard.origin.y;
			CGFloat yCoordinate   = currentCard.origin.y + deltaDistance;
			[currentCard setYCoordinate:yCoordinate];
		}
	}
}

@end


//------------------------------------------------------------------------------
#pragma mark - KLControllerCard
//------------------------------------------------------------------------------
@interface KLControllerCard ()
- (void)shrinkCardToScaledSize:(BOOL)animated;
- (void)expandCardToFullSize:(BOOL)animated;
@end

@implementation KLControllerCard

- (id)initWithNoteViewController:(KLNoteViewController *)noteView
			navigationController:(UINavigationController *)navigationController
						   index:(NSInteger)_index
{

	if (self = [super init])
	{
		self.noteViewController   = noteView;
		self.navigationController = navigationController;

		//Set the instance variables
		index   = _index;
		originY = [noteView defaultVerticalOriginForControllerCard:self
		                                                   atIndex:index];
		[self setFrame:noteView.view.bounds];

		//Initialize the view's properties
		[self setAutoresizesSubviews:YES];
		[self setAutoresizingMask:self.noteViewController.cardAutoresizingMask];

		[self addSubview:navigationController.view];

		//Configure navigation controller to have rounded edges while maintaining shadow
		[self.navigationController.view.layer setCornerRadius:self.noteViewController.cardCornerRadius];
		[self.navigationController.view setClipsToBounds:YES];
		
		//Add Pan Gesture
		UIPanGestureRecognizer *panGesture =\
			[[UIPanGestureRecognizer alloc]
			 initWithTarget:self
			 action:@selector(didPerformPanGesture:)];
		
		//Add the gesture to the navigation bar
		if (self.noteViewController.cardPanGestureScope == KLControllerCardPanGestureScopeNavigationControllerView)
		{
			[self.navigationController.view addGestureRecognizer:panGesture];
		}
		else
		{
			[self.navigationController.navigationBar addGestureRecognizer:panGesture];
		}

		panGesture.delegate = self;

		//Add long touch recognizer
		if (self.noteViewController.cardEnablePressGesture)
		{
			UILongPressGestureRecognizer *pressGesture = \
				[[UILongPressGestureRecognizer alloc]
				 initWithTarget:self
				 action:@selector(didPerformLongPress:)];
			
			[pressGesture setMinimumPressDuration:self.noteViewController.cardMinimumPressDuration];
			
			//Add the gesture to the navigation bar
			[self.navigationController.navigationBar addGestureRecognizer:pressGesture];

			pressGesture.delegate = self;
		}

		//Initialize the state to default
		[self
		 setState:KLControllerCardStateDefault
		 animated:NO];
	}
	return self;
}

-(void)dealloc
{
	self.navigationController = nil;
	self.noteViewController = nil;
	self.delegate = nil;
	[super dealloc];
}


#pragma mark - UIGestureRecognizer action handlers
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return YES;
}

- (void)didPerformLongPress:(UILongPressGestureRecognizer *)recognizer
{
	if (self.state == KLControllerCardStateDefault && recognizer.state == UIGestureRecognizerStateEnded)
	{
		//Go to full size
		[self setState:KLControllerCardStateFullScreen animated:YES];
	}
}

- (void)redrawShadow
{
	if (self.noteViewController.cardShadowEnabled)
	{
		UIBezierPath *path = \
			[UIBezierPath
			 bezierPathWithRoundedRect:[self bounds]
			 cornerRadius:self.noteViewController.cardCornerRadius];

		[self.layer setShadowOpacity:self.noteViewController.cardShadowOpacity];
		[self.layer setShadowOffset:self.noteViewController.cardShadowOffset];
		[self.layer setShadowRadius:self.noteViewController.cardShadowRadius];
		[self.layer setShadowColor:[self.noteViewController.cardShadowColor CGColor]];
		[self.layer setShadowPath:[path CGPath]];
	}
}

- (void)didPerformPanGesture:(UIPanGestureRecognizer *)recognizer
{
	CGPoint location    = [recognizer locationInView:self.noteViewController.view];
	CGPoint translation = [recognizer translationInView:self];
	
	if (recognizer.state == UIGestureRecognizerStateBegan)
	{
		//Begin animation
		if (self.state == KLControllerCardStateFullScreen)
		{
			//Shrink to regular size
			[self shrinkCardToScaledSize:YES];
		}
		//Save the offet to add to the height
		self.panOriginOffset = [recognizer locationInView:self].y;
	}
	else if (recognizer.state == UIGestureRecognizerStateChanged)
	{
		//Check if panning downwards and move other cards
		if (translation.y > 0)
		{
			//Panning downwards from Full screen state
			if (self.state == KLControllerCardStateFullScreen && self.frame.origin.y < originY)
			{
				//Notify delegate so it can update the coordinates of the other cards unless user has travelled past the origin y coordinate
				if ([self.delegate respondsToSelector:@selector(controllerCard:didUpdatePanPercentage:)])
				{
					[self.delegate controllerCard:self didUpdatePanPercentage:[self percentageDistanceTravelled]];
				}
			}
			//Panning downwards from default state
			else if (self.state == KLControllerCardStateDefault && self.frame.origin.y > originY)
			{
				//Implements behavior such that when originating at the default position and scrolling down, all other cards below the scrolling card move down at the same rate
				if ([self.delegate respondsToSelector:@selector(controllerCard:didUpdatePanPercentage:)])
				{
					[self.delegate controllerCard:self didUpdatePanPercentage:[self percentageDistanceTravelled]];
				}
			}
		}

		//Track the movement of the users finger during the swipe gesture
		[self setYCoordinate:location.y - self.panOriginOffset];
	}
	else if (recognizer.state == UIGestureRecognizerStateEnded)
	{
		//Check if it should return to the origin location
		if ([self shouldReturnToState:self.state fromPoint:[recognizer translationInView:self]])
		{
			[self setState:self.state animated:YES];
		}
		else
		{
			//Toggle state between full screen and default if it doesnt return to the current state
			[self
			 setState:self.state == KLControllerCardStateFullScreen ? KLControllerCardStateDefault:KLControllerCardStateFullScreen
			 animated:YES];
		}
	}
}

#pragma mark - Handle resizing of card

- (void)shrinkCardToScaledSize:(BOOL)animated
{

	//Set the scaling factor if not already set
	if (!scalingFactor)
	{
		scalingFactor = [self.noteViewController scalingFactorForIndex:index];
	}
	
	//If animated then animate the shrinking else no animation
	if (animated)
	{
		[UIView
		 animateWithDuration:self.noteViewController.cardAnimationDuration
		 animations:^{
			 //Slightly recursive to reduce duplicate code
			 [self shrinkCardToScaledSize:NO];
		 }];
	}
	else
	{
		[self setTransform:CGAffineTransformMakeScale(scalingFactor, scalingFactor)];
	}
}

- (void)expandCardToFullSize:(BOOL)animated
{
	//Set the scaling factor if not already set
	if (!scalingFactor)
	{
		scalingFactor = [self.noteViewController scalingFactorForIndex:index];
	}
	
	//If animated then animate the shrinking else no animation
	if (animated)
	{
		[UIView
		 animateWithDuration:self.noteViewController.cardAnimationDuration
		 animations:^{
			 //Slightly recursive to reduce duplicate code
			 [self expandCardToFullSize:NO];
		 }];
	}
	else
	{
		[self
		 setTransform:
			CGAffineTransformMakeScale(self.noteViewController.cardMaximizedScalingFactor, self.noteViewController.cardMaximizedScalingFactor)];
	}
}

#pragma mark - Handle state changes for card

- (void)setState:(KLControllerCardState)state
		animated:(BOOL)animated
{
	if (animated)
	{
		[UIView
		 animateWithDuration:self.noteViewController.cardAnimationDuration animations:^{
			[self setState:state animated:NO];
		 } completion:^(BOOL finished) {
			 if (state == KLControllerCardStateFullScreen)
			 {
				// Fix scaling bug when expand to full size
				self.frame = self.noteViewController.view.bounds;
				self.navigationController.view.frame = self.frame;
				self.navigationController.view.layer.cornerRadius = 0;
			 }
		 }];
		return;
	}

	// Set corner radius
	[self.navigationController.view.layer
	 setCornerRadius:self.noteViewController.cardCornerRadius];

	//Full Screen State
	if (state == KLControllerCardStateFullScreen)
	{
		[self expandCardToFullSize:animated];
		[self setYCoordinate:0];
	}
	//Default State
	else if (state == KLControllerCardStateDefault)
	{
		[self shrinkCardToScaledSize:animated];
		[self setYCoordinate:originY];
	}
	//Hidden State - Bottom
	else if (state == KLControllerCardStateHiddenBottom)
	{
		//Move it off screen and far enough down that the shadow does not appear on screen
		[self setYCoordinate:self.noteViewController.view.frame.size.height + abs (self.noteViewController.cardShadowOffset.height) * 3];
	}
	//Hidden State - Top
	else if (state == KLControllerCardStateHiddenTop)
	{
		[self setYCoordinate:0];
	}

	//Notify the delegate of the state change (even if state changed to self)
	KLControllerCardState lastState = self.state;

	//Update to the new state
	[self setState:state];

	//Notify the delegate
	if ([self.delegate respondsToSelector:@selector(controllerCard:didChangeToDisplayState:fromDisplayState:)])
	{
		[self.delegate
		 controllerCard:self
		 didChangeToDisplayState:state
		 fromDisplayState:lastState];
	}
}

#pragma mark - Various data helpers

- (CGPoint)origin
{
	return CGPointMake(0, originY);
}

- (CGFloat)percentageDistanceTravelled
{
	return self.frame.origin.y / originY;
}

//Boolean for determining if the movement was sufficient to warrent changing states
- (BOOL)shouldReturnToState:(KLControllerCardState)state fromPoint:(CGPoint)point
{
	if (state == KLControllerCardStateFullScreen)
	{
		return ABS(point.y) < self.navigationController.navigationBar.frame.size.height;
	}
	else if (state == KLControllerCardStateDefault)
	{
		return point.y > -self.navigationController.navigationBar.frame.size.height;
	}

	return NO;
}

- (void)setYCoordinate:(CGFloat)yValue
{
	[self setFrame:CGRectMake(self.frame.origin.x, yValue, self.frame.size.width, self.frame.size.height)];
}

- (void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
	[self redrawShadow];
}

@end
