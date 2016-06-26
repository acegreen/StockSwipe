//
// MDCSwipeToChooseViewOptions.h
//
// Copyright (c) 2014 to present, Brian Gesiak @modocache
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import "MDCSwipeOptions.h"

/*!
 * `MDCSwipeToChooseViewOptions` may be used to customize the behavior and
 * appearance of a `MDCSwipeToChooseView`.
 */
@interface MDCSwipeToChooseViewOptions : NSObject

/*!
 * The delegate that receives messages pertaining to the swipe choices of the view.
 */
@property (nonatomic, weak) id<MDCSwipeToChooseDelegate> delegate;

/*!
 * The text displayed in the `likedView`. A default value is provided in the
 * `-init` method.
 */
@property (nonatomic, copy) NSString *longText;

/*!
 * The color of the text and border of the `likedView`. A default value is provided in the
 * `-init` method.
 */
@property (nonatomic, strong) UIColor *longColor;

/*!
 * The image used to displayed in the `likeView`. If this is present, it will take
 * precedence over the likeText
 */
@property (nonatomic, strong) UIImage *longImage;

/*!
 * The rotation angle of the `likedView`. A default value is provided in the
 * `-init` method.
 */
@property (nonatomic, assign) CGFloat longRotationAngle;

/*!
 * The text displayed in the `nopeView`. A default value is provided in the
 * `-init` method.
 */
@property (nonatomic, copy) NSString *shortText;

/*!
 * The color of the text and border of the `nopeView`. A default value is provided in the
 * `-init` method.
 */
@property (nonatomic, strong) UIColor *shortColor;

/*!
 * The image used to displayed in the `likeView`. If this is present, it will take
 * precedence over the likeText
 */
@property (nonatomic, strong) UIImage *shortImage;

/*!
 * The rotation angle of the `nopeView`. A default value is provided in the
 * `-init` method.
 */
@property (nonatomic, assign) CGFloat shortRotationAngle;

/*!
 * The text displayed in the `skipView`. A default value is provided in the
 * `-init` method.
 */
@property (nonatomic, copy) NSString *skipText;

/*!
 * The color of the text and border of the `skipView`. A default value is provided in the
 * `-init` method.
 */
@property (nonatomic, strong) UIColor *skipColor;

/*!
 * The image used to displayed in the `likeView`. If this is present, it will take
 * precedence over the likeText
 */
@property (nonatomic, strong) UIImage *skipImage;

/*!
 * The rotation angle of the `skipView`. A default value is provided in the
 * `-init` method.
 */
@property (nonatomic, assign) CGFloat skipRotationAngle;

/*!
 * The distance, in pixels, that a view must be panned in order to constitue a selection.
 * For example, if the `threshold` is `100.f`, panning the view `101.f` pixels to the right
 * is considered a selection in the `MDCSwipeDirectionRight` direction. A default value is
 * provided in the `-init` method.
 */
@property (nonatomic, assign) CGFloat threshold;

/*!
 * A callback to be executed when the view is panned. The block takes an instance of
 * `MDCPanState` as an argument. Use this `state` instance to determine the pan direction
 * and the distance until the threshold is reached.
 */
@property (nonatomic, copy) MDCSwipeToChooseOnPanBlock onPan;

/*!
 * By default, user should be allowed to use gesture to swipe the view.
 * By disable this property, user can only swipe the view programmatically
 */
@property (nonatomic, assign) BOOL swipeEnabled;

@end
