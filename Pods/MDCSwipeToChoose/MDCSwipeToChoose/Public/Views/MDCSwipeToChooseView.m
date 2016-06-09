//
// MDCSwipeToChooseView.m
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

#import "MDCSwipeToChooseView.h"
#import "MDCSwipeToChoose.h"
#import "MDCGeometry.h"
#import "UIView+MDCBorderedLabel.h"
#import "UIColor+MDCRGB8Bit.h"
#import <QuartzCore/QuartzCore.h>

//static CGFloat const MDCSwipeToChooseViewHorizontalPadding = 30.f;
//static CGFloat const MDCSwipeToChooseViewTopPadding = 50.f;
static CGFloat const MDCSwipeToChooseViewLabelWidth = 150.f;
static CGFloat const MDCSwipeToChooseViewLabelHeight = 75.f;

@interface MDCSwipeToChooseView ()
@property (nonatomic, strong) MDCSwipeToChooseViewOptions *options;
@end

@implementation MDCSwipeToChooseView

#pragma mark - Object Lifecycle

- (instancetype)initWithFrame:(CGRect)frame options:(MDCSwipeToChooseViewOptions *)options {
    self = [super initWithFrame:frame];
    if (self) {
        _options = options ? options : [MDCSwipeToChooseViewOptions new];
        
        [self setupView];
        
    }
    return self;
}

- (void) layoutSubviews {

    [self constructLongOverlayView];
    [self constructShortOverlayImageView];
    [self constructSkipOverlayImageView];
    [self setupSwipeToChoose];
    
    [self bringSubviewToFront:self];
    
}

#pragma mark - Internal Methods

- (void)setupView {
    
    self.backgroundColor = [UIColor clearColor];
    self.layer.masksToBounds = true;
    self.layer.cornerRadius = 15.f;
    self.layer.borderWidth = 1.f;
    self.layer.borderColor = [UIColor grayColor].CGColor;
    
}

- (void)constructLongOverlayView {
    
    self.longView = [[UIImageView alloc] initWithFrame:CGRectMake((CGRectGetMidX(self.bounds) - (MDCSwipeToChooseViewLabelWidth / 2)),
                                                                   (CGRectGetMidY(self.bounds) - (MDCSwipeToChooseViewLabelHeight / 2)),
                                                                   MDCSwipeToChooseViewLabelWidth,
                                                                   MDCSwipeToChooseViewLabelHeight)];
    [self.longView constructBorderedLabelWithText:self.options.longText
                                             color:self.options.longColor
                                             angle:self.options.longRotationAngle];
    self.longView.alpha = 0.f;
    
    if (![_longView isDescendantOfView:self]) {
    
        [self addSubview:self.longView];
        
    }
}

- (void)constructShortOverlayImageView {
    
    self.shortView = [[UIImageView alloc] initWithFrame:CGRectMake((CGRectGetMidX(self.bounds) - (MDCSwipeToChooseViewLabelWidth / 2)),
                                                                  (CGRectGetMidY(self.bounds) - (MDCSwipeToChooseViewLabelHeight / 2)),
                                                                  MDCSwipeToChooseViewLabelWidth,
                                                                  MDCSwipeToChooseViewLabelHeight)];
    [self.shortView constructBorderedLabelWithText:self.options.shortText
                                            color:self.options.shortColor
                                            angle:self.options.shortRotationAngle];
    
    self.shortView.alpha = 0.f;
    
    if (![_shortView isDescendantOfView:self]) {
        
        [self addSubview:self.shortView];
        
    }
}

- (void)constructSkipOverlayImageView {
    
    self.skipView = [[UIImageView alloc] initWithFrame:CGRectMake((CGRectGetMidX(self.bounds) - (MDCSwipeToChooseViewLabelWidth / 2)),
                                                                  (CGRectGetMidY(self.bounds) - (MDCSwipeToChooseViewLabelHeight / 2)),
                                                                  MDCSwipeToChooseViewLabelWidth,
                                                                  MDCSwipeToChooseViewLabelHeight)];
    [self.skipView constructBorderedLabelWithText:self.options.skipText
                                            color:self.options.skipColor
                                            angle:self.options.skipRotationAngle];
    
    self.skipView.alpha = 0.f;

    if (![_skipView isDescendantOfView:self]) {
        
        [self addSubview:self.skipView];
        
    }
}

- (void)setupSwipeToChoose {
    MDCSwipeOptions *options = [MDCSwipeOptions new];
    options.delegate = self.options.delegate;
    options.threshold = self.options.threshold;
    options.allowedSwipeDirections = self.options.allowedSwipeDirections;
    
    __block UIView *longImageView = self.longView;
    __block UIView *shortImageView = self.shortView;
    __block UIView *skipImageView = self.skipView;
    __weak MDCSwipeToChooseView *weakself = self;
    
    options.onPan = ^(MDCPanState *state) {
        
        if (state.direction == MDCSwipeDirectionNone) {
            
            longImageView.alpha = 0.f;
            shortImageView.alpha = 0.f;
            skipImageView.alpha = 0.f;
            
        } else if (state.direction == MDCSwipeDirectionLeft) {
            
            longImageView.alpha = 0.f;
            shortImageView.alpha = state.thresholdRatio;
            skipImageView.alpha = 0.f;
            
        } else if (state.direction == MDCSwipeDirectionRight) {
            
            longImageView.alpha = state.thresholdRatio;
            shortImageView.alpha = 0.f;
            skipImageView.alpha = 0.f;
            
        } else if (state.direction == MDCSwipeDirectionUp) {
            
            longImageView.alpha = 0.f;
            shortImageView.alpha = 0.f;
            skipImageView.alpha = state.thresholdRatio;
            
        } else if (state.direction == MDCSwipeDirectionDown) {
            
            longImageView.alpha = 0.f;
            shortImageView.alpha = 0.f;
            skipImageView.alpha = 0.f;
        }
        
        if (weakself.options.onPan) {
            weakself.options.onPan(state);
        }
    };
    
    [self mdc_swipeToChooseSetup:options];
}

@end
