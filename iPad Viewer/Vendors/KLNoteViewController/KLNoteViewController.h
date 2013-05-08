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

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

//------------------------------------------------------------------------------
#pragma mark - KLControllerCardDelegate
//------------------------------------------------------------------------------

@class KLNoteViewController;
@class KLControllerCard;
@protocol KLNoteViewControllerDataSource;
@protocol KLNoteViewControllerDelegate;

enum
{
	KLControllerCardStateHiddenBottom,						//Card is hidden off screen (Below bottom of visible area)
	KLControllerCardStateHiddenTop,							//Card is hidden off screen (At top of visible area)
	KLControllerCardStateDefault,							//Default location for the card
	KLControllerCardStateFullScreen							//Highlighted location for the card
};
typedef UInt32 KLControllerCardState;

enum
{
	KLControllerCardPanGestureScopeNavigationBar,           // the pan gesture only works from the navigation bar
	KLControllerCardPanGestureScopeNavigationControllerView // the pan gesture works on the whole card view
};
typedef UInt32 KLControllerCardPanGestureScope;

@protocol KLControllerCardDelegate <NSObject>
@optional
//Called on any time a state change has occured - even if a state has changed to itself - (i.e. from KLControllerCardStateDefault to KLControllerCardStateDefault)
- (void)controllerCard:(KLControllerCard *)controllerCard
didChangeToDisplayState:(KLControllerCardState)toState
	  fromDisplayState:(KLControllerCardState)fromState;

//Called when user is panning and a the card has travelled X percent of the distance to the top - Used to redraw other cards during panning fanout
- (void)controllerCard:(KLControllerCard *)controllerCard
didUpdatePanPercentage:(CGFloat)percentage;
@end


//------------------------------------------------------------------------------
#pragma mark - KLControllerCard
//------------------------------------------------------------------------------
//KLController card encapsulates the UINavigationController handling all the resizing and state management for the view. It has no concept of the other cards or world outside of itself.
@interface KLControllerCard : UIView<UIGestureRecognizerDelegate>
{
	@private
	CGFloat originY;
	CGFloat scalingFactor;
	NSInteger index;
}
@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, assign) KLNoteViewController *noteViewController;
@property (nonatomic, assign) id<KLControllerCardDelegate> delegate;
@property (nonatomic, assign) CGPoint origin;
@property (nonatomic, assign) CGFloat panOriginOffset;
@property (nonatomic, assign) KLControllerCardState state;
- (id)initWithNoteViewController:(KLNoteViewController *)noteView
			navigationController:(UINavigationController *)navigationController
						   index:(NSInteger)index;
- (void)setState:(KLControllerCardState)state animated:(BOOL)animated;
- (void)setYCoordinate:(CGFloat)yValue;
- (CGFloat)percentageDistanceTravelled;
@end

//------------------------------------------------------------------------------
#pragma mark - KLNoteViewController
//------------------------------------------------------------------------------
//KLNoteViewController manages the cards interfacing between the various cards
@interface KLNoteViewController : BaseViewController  <KLControllerCardDelegate>
{
	NSInteger totalCards;
}
@property (nonatomic, assign) id<KLNoteViewControllerDataSource> dataSource;
@property (nonatomic, assign) id<KLNoteViewControllerDelegate> delegate;

//Navigation bar properties
@property (nonatomic, assign) Class cardNavigationBarClass; //Use a custom class for the card navigation bar

//Layout properties
@property (nonatomic ,assign) CGFloat cardMinimizedScalingFactor;   //Amount to shrink each card from the previous one
@property (nonatomic ,assign) CGFloat cardMaximizedScalingFactor;   //Maximum a card can be scaled to
@property (nonatomic ,assign) CGFloat cardNavigationBarOverlap;     //Defines vertical overlap of each navigation toolbar. Slight hack that prevents rounding errors from showing the whitespace between navigation toolbars. Can be customized if require more/less packing of navigation toolbars

//Animation properties
@property (nonatomic ,assign) NSTimeInterval cardAnimationDuration;             //Amount of time for the animations to occur
@property (nonatomic ,assign) NSTimeInterval cardReloadHideAnimationDuration;
@property (nonatomic ,assign) NSTimeInterval cardReloadShowAnimationDuration;

//Position for the stack of navigation controllers to originate at
@property (nonatomic ,assign) CGFloat cardVerticalOrigin;           //Vertical origin of the controller card stack. Making this value larger/smaller will make the card shift down/up.

//Corner radius properties
@property (nonatomic ,assign) CGFloat cardCornerRadius;

//Shadow Properties - Note : Disabling shadows greatly improves performance and fluidity of animations
@property (nonatomic ,assign) BOOL cardShadowEnabled;
@property (nonatomic ,strong) UIColor *cardShadowColor;
@property (nonatomic ,assign) CGSize cardShadowOffset;
@property (nonatomic ,assign) CGFloat cardShadowRadius;
@property (nonatomic ,assign) CGFloat cardShadowOpacity;

//Gesture properties
@property (nonatomic ,assign) KLControllerCardPanGestureScope cardPanGestureScope;
@property (nonatomic ,assign) BOOL cardEnablePressGesture;
@property (nonatomic ,assign) NSTimeInterval cardMinimumPressDuration;

//Autoresizing mask used for the card controller
@property (nonatomic ,assign) UIViewAutoresizing cardAutoresizingMask;

//KLControllerCards in an array. Object at index 0 will appear at bottom of the stack, and object at position (size-1) will appear at the top
@property (nonatomic, strong) NSArray *controllerCards;

//Repopulates all data for the controllerCards array
- (void)reloadData;
- (void)reloadDataAnimated:(BOOL)animated;

//Helpers for getting information about the controller cards
- (NSInteger)numberOfControllerCardsInNoteView:(KLNoteViewController *)noteView;
- (UIViewController *)noteView:(KLNoteViewController *)noteView viewControllerForRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForControllerCard:(KLControllerCard *)controllerCard;
- (void)noteViewController:(KLNoteViewController *)noteViewController
   didUpdateControllerCard:(KLControllerCard *)controllerCard
			toDisplayState:(KLControllerCardState)toState
		  fromDisplayState:(KLControllerCardState)fromState;
@end

//------------------------------------------------------------------------------
#pragma mark - KLNoteViewControllerDelegate
//------------------------------------------------------------------------------
@protocol   KLNoteViewControllerDelegate <NSObject>
@optional
//Called on any time a state change has occured - even if a state has changed to itself - (i.e. from KLControllerCardStateDefault to KLControllerCardStateDefault)
- (void)noteViewController:(KLNoteViewController *)noteViewController
   didUpdateControllerCard:(KLControllerCard *)controllerCard
			toDisplayState:(KLControllerCardState)toState
		  fromDisplayState:(KLControllerCardState)fromState;
@end

//------------------------------------------------------------------------------
#pragma mark - KLNoteViewControllerDataSource
//------------------------------------------------------------------------------
@protocol   KLNoteViewControllerDataSource <NSObject>
@required
//Called when the NoteViewController needs to know how many controller cards to expect
- (NSInteger)numberOfControllerCardsInNoteView:(KLNoteViewController *)noteView;
//Called to populate the controllerCards array - Automatically maps the UINavigationController to KLControllerCard and adds to array
- (UIViewController *)noteView:(KLNoteViewController *)noteView
viewControllerForRowAtIndexPath:(NSIndexPath *)indexPath;
@end