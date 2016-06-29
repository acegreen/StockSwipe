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

static CGFloat const MDCSwipeToChooseViewHorizontalPadding = 30.f;
static CGFloat const MDCSwipeToChooseViewTopPadding = 50.f;
static CGFloat const MDCSwipeToChooseViewImageTopPadding = 150.f;
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
        [self constructContentView];
        [self constructLongView];
        [self constructShortView];
        [self constructSkipView];
        [self setupSwipeToChoose];
    }
    return self;
}

#pragma mark - Internal Methods

- (void)setupView {
    self.backgroundColor = [UIColor clearColor];
    self.layer.cornerRadius = 15.f;
    self.layer.masksToBounds = YES;
    self.layer.borderWidth = 0.5;
    self.layer.borderColor = [UIColor mdc_colorWith8BitRed:111.f
                                                 green:113.f
                                                  blue:121.f
                                                 alpha:1.f].CGColor;
}

- (void)constructContentView {
    _contentView = [[UIView alloc] initWithFrame:self.bounds];
    _contentView.clipsToBounds = YES;
    [self addSubview:_contentView];
}

- (void)constructLongView {
//    CGFloat yOrigin = (self.options.longImage ? MDCSwipeToChooseViewImageTopPadding : MDCSwipeToChooseViewTopPadding);

    CGRect frame = CGRectMake((CGRectGetMidX(self.bounds) - (MDCSwipeToChooseViewLabelWidth / 2)),
                              (CGRectGetMidY(self.bounds) - (MDCSwipeToChooseViewLabelHeight / 2)),
                              MDCSwipeToChooseViewLabelWidth,
                              MDCSwipeToChooseViewLabelHeight);
    if (self.options.longImage) {
        self.longView = [[UIImageView alloc] initWithImage:self.options.longImage];
        self.longView.frame = frame;
        self.longView.contentMode = UIViewContentModeScaleAspectFit;
    } else {
        self.longView = [[UIView alloc] initWithFrame:frame];
        [self.longView constructBorderedLabelWithText:self.options.longText
                                                 color:self.options.longColor
                                                 angle:self.options.longRotationAngle];
    }
    self.longView.alpha = 0.f;
    [self.contentView addSubview:self.longView];
}

- (void)constructShortView {
    CGFloat width = CGRectGetMidX(self.contentView.bounds);
//    CGFloat xOrigin = CGRectGetMaxX(self.contentView.bounds) - width - MDCSwipeToChooseViewHorizontalPadding;
//    CGFloat yOrigin = (self.options.shortImage ? MDCSwipeToChooseViewImageTopPadding : MDCSwipeToChooseViewTopPadding);
    CGRect frame = CGRectMake((CGRectGetMidX(self.bounds) - (MDCSwipeToChooseViewLabelWidth / 2)),
                              (CGRectGetMidY(self.bounds) - (MDCSwipeToChooseViewLabelHeight / 2)),
                              MDCSwipeToChooseViewLabelWidth,
                              MDCSwipeToChooseViewLabelHeight);
    if (self.options.shortImage) {
        self.shortView = [[UIImageView alloc] initWithImage:self.options.shortImage];
        self.shortView.frame = frame;
        self.shortView.contentMode = UIViewContentModeScaleAspectFit;
    } else {
        self.shortView = [[UIView alloc] initWithFrame:frame];
        [self.shortView constructBorderedLabelWithText:self.options.shortText
                                                color:self.options.shortColor
                                                angle:self.options.shortRotationAngle];
    }
    self.shortView.alpha = 0.f;
    [self.contentView addSubview:self.shortView];
}

- (void)constructSkipView {
    CGFloat width = CGRectGetMidX(self.contentView.bounds);
//    CGFloat xOrigin = CGRectGetMaxX(self.contentView.bounds) - width - MDCSwipeToChooseViewHorizontalPadding;
//    CGFloat yOrigin = (self.options.skipImage ? MDCSwipeToChooseViewImageTopPadding : MDCSwipeToChooseViewTopPadding);
    CGRect frame = CGRectMake((CGRectGetMidX(self.bounds) - (MDCSwipeToChooseViewLabelWidth / 2)),
                              (CGRectGetMidY(self.bounds) - (MDCSwipeToChooseViewLabelHeight / 2)),
                              MDCSwipeToChooseViewLabelWidth,
                              MDCSwipeToChooseViewLabelHeight);
    if (self.options.skipImage) {
        self.skipView = [[UIImageView alloc] initWithImage:self.options.skipImage];
        self.skipView.frame = frame;
        self.skipView.contentMode = UIViewContentModeScaleAspectFit;
    } else {
        self.skipView = [[UIView alloc] initWithFrame:frame];
        [self.skipView constructBorderedLabelWithText:self.options.skipText
                                                color:self.options.skipColor
                                                angle:self.options.skipRotationAngle];
    }
    self.skipView.alpha = 0.f;
    [self.contentView addSubview:self.skipView];
}

- (void)setupSwipeToChoose {
    MDCSwipeOptions *options = [MDCSwipeOptions new];
    options.delegate = self.options.delegate;
    options.threshold = self.options.threshold;
    options.swipeEnabled = self.options.swipeEnabled;

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
