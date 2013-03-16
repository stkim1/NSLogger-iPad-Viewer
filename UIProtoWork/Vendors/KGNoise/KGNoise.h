/*
 * Copyright (c) 2012 David Keegan (http://davidkeegan.com)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy 
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights 
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
 * copies of the Software, and to permit persons to whom the Software is 
 * furnished to do so, subject to the following conditions:
 
 * The above copyright notice and this permission notice shall be included in 
 * all copies or substantial portions of the Software.
 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#pragma mark - KGNoise

@interface KGNoise : NSObject

+ (void)drawNoiseWithOpacity:(CGFloat)opacity;
+ (void)drawNoiseWithOpacity:(CGFloat)opacity andBlendMode:(CGBlendMode)blendMode;

@end

#pragma mark - KGNoise Color

#if TARGET_OS_IPHONE
@interface UIColor(KGNoise)
- (UIColor *)colorWithNoiseWithOpacity:(CGFloat)opacity;
- (UIColor *)colorWithNoiseWithOpacity:(CGFloat)opacity andBlendMode:(CGBlendMode)blendMode;
@end
#else
@interface NSColor(KGNoise)
- (NSColor *)colorWithNoiseWithOpacity:(CGFloat)opacity;
- (NSColor *)colorWithNoiseWithOpacity:(CGFloat)opacity andBlendMode:(CGBlendMode)blendMode;
@end
#endif

#pragma mark - KGNoiseView

#if TARGET_OS_IPHONE
@interface KGNoiseView : UIView
#else
@interface KGNoiseView : NSView
@property (strong, nonatomic) NSColor *backgroundColor;
#endif
@property (nonatomic) CGFloat noiseOpacity;
@property (nonatomic) CGBlendMode noiseBlendMode;
@end

#pragma mark - KGNoiseLinearGradientView

NS_ENUM(NSUInteger, KGLinearGradientDirection){
    KGLinearGradientDirection0Degrees, // Left to Right
    KGLinearGradientDirection90Degrees, // Bottom to Top
    KGLinearGradientDirection180Degrees, // Right to Left
    KGLinearGradientDirection270Degrees // Top to Bottom
};

@interface KGNoiseLinearGradientView : KGNoiseView
#if TARGET_OS_IPHONE
@property (strong, nonatomic) UIColor *alternateBackgroundColor;
#else
@property (strong, nonatomic) NSColor *alternateBackgroundColor;
#endif
@property (nonatomic) enum KGLinearGradientDirection gradientDirection;
@end

#pragma mark - KGNoiseRadialGradientView

@interface KGNoiseRadialGradientView : KGNoiseView
#if TARGET_OS_IPHONE
@property (strong, nonatomic) UIColor *alternateBackgroundColor;
#else
@property (strong, nonatomic) NSColor *alternateBackgroundColor;
#endif
@end
