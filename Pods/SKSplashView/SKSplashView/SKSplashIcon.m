//
//  SKSplashIcon.m
//  SKSplashView
//
//  Created by Sachin Kesiraju on 10/25/14.
//  Copyright (c) 2014 Sachin Kesiraju. All rights reserved.
//

#import "SKSplashIcon.h"

@interface SKSplashIcon()

@property (readwrite, assign) SKIconAnimationType preAnimationType;
@property (readwrite, assign) SKIconAnimationType postAnimationType;
@property (strong, nonatomic) CAAnimation *customAnimation;
@property (nonatomic) CGFloat animationDuration;
@property (nonatomic) BOOL indefiniteAnimation;
@property (strong, nonatomic) UIImage *iconImage;
@property (nonatomic) CGSize initialSize;

@end

@implementation SKSplashIcon

@dynamic animationDuration;

#pragma mark - Initialization

- (instancetype) initWithImage:(UIImage *)iconImage
{
    self = [super init];
    if(self) {
        _initialSize = iconImage.size;
        self.image = iconImage;
        self.tintColor = _iconColor;
        self.contentMode = UIViewContentModeScaleAspectFit;
        self.frame = CGRectMake(0, 0, iconImage.size.width, iconImage.size.height);
    }
    
    return self;
}

- (instancetype) initWithImage:(UIImage *)iconImage animationType:(SKIconAnimationType)animationType
{
    self = [super init];
    if(self) {
        _preAnimationType = animationType;
        _iconImage = iconImage;
        _initialSize = iconImage.size;
        self.image = [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.image = iconImage;
        self.tintColor = _iconColor;
        self.contentMode = UIViewContentModeScaleAspectFit;
        self.frame = CGRectMake(0, 0, iconImage.size.width, iconImage.size.height);
    }
    
    return self;
}

- (instancetype) initWithImage:(UIImage *)iconImage initialSize:(CGSize)initialSize preAnimationType:(SKIconAnimationType)preAnimationType postAnimationType:(SKIconAnimationType)postAnimationType
{
    self = [super init];
    if(self)
    {
        _preAnimationType = preAnimationType;
        _iconImage = iconImage;
        _initialSize = initialSize;
        self.image = [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.image = iconImage;
        self.tintColor = _iconColor;
        self.contentMode = UIViewContentModeScaleAspectFit;
        self.frame =  CGRectMake(0, 0, _initialSize.width, _initialSize.height);
    }
    
    return self;
}

- (void) setIconAnimationType:(SKIconAnimationType)animationType
{
    _preAnimationType = animationType;
}

- (void) setPostIconAnimationType:(SKIconAnimationType)animationType
{
    _postAnimationType = animationType;
}

- (void) setCustomAnimation:(CAAnimation *)animation
{
    _customAnimation = animation;
}

- (void) setIconSize:(CGSize)iconSize
{
    self.frame = CGRectMake(0, 0, iconSize.width, iconSize.height);
}

- (UIColor *)iconColor
{
    if (!_iconColor) {
        _iconColor = [UIColor whiteColor];
    }
    return _iconColor;
}

#pragma mark - Implementation

- (void) startAnimation:(SKIconAnimationType)animationType;
{
    [self startAnimationWithDuration:animationType :0];
}


- (void) startAnimationWithDuration:(SKIconAnimationType)animationType:(CGFloat)animationDuration
{
    
    switch (animationType)
    {
        case SKIconAnimationTypeBounce:
            [self addBounceAnimation];
            break;
        case SKIconAnimationTypeFade:
            [self addFadeAnimation];
            break;
        case SKIconAnimationTypeGrow:
            [self addGrowAnimation];
            break;
        case SKIconAnimationTypeShrink:
            [self addShrinkAnimation];
            break;
        case SKIconAnimationTypePing:
            [self addPingAnimation];
            break;
        case SKIconAnimationTypeBlink:
            [self addBlinkAnimation];
            break;
        case SKIconAnimationTypeNone:
            [self addNoAnimation];
            break;
        case SKIconAnimationTypeCustom:
            [self addCustomAnimation:_customAnimation];
            break;
        default:NSLog(@"No animation type selected");
            break;
    }
    
    if(animationDuration != 0) { //if start animation, set duration if any
        self.animationDuration = animationDuration;
        [NSTimer scheduledTimerWithTimeInterval:self.animationDuration target:self selector:@selector(removeAnimations) userInfo:nil repeats:YES];
    } else {
        self.indefiniteAnimation = YES;
    }
}

#pragma mark - Animations

- (void) addBounceAnimation
{
    CGFloat shrinkDuration = self.animationDuration * 0.6;
    CGFloat growDuration = self.animationDuration * 0.4;
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    CGFloat scaleX = width / self.initialSize.width;
    CGFloat scaleY = height / self.initialSize.height;
    CGFloat minScale = MIN(scaleX,scaleY);
    printf("%f", minScale);
    
    [UIView animateWithDuration:shrinkDuration delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:10 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGAffineTransform scaleTransform = CGAffineTransformMakeScale(0.90, 0.90);
        self.transform = scaleTransform;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:growDuration animations:^{
            CGAffineTransform scaleTransform = CGAffineTransformMakeScale(minScale, minScale);
            self.transform = scaleTransform;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    }];
}

- (void) addFadeAnimation
{
    [UIView animateWithDuration:self.animationDuration animations:^{
        self.image = _iconImage;
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void) addGrowAnimation
{
    [UIView animateWithDuration:self.animationDuration animations:^{
        CGAffineTransform scaleTransform = CGAffineTransformMakeScale(20, 20);
        self.transform = scaleTransform;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void) addShrinkAnimation
{
    [UIView animateWithDuration:self.animationDuration delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:10 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGAffineTransform scaleTransform = CGAffineTransformMakeScale(0.75, 0.75);
        self.transform = scaleTransform;
    } completion:^(BOOL finished)
     {
         [self removeFromSuperview];
     }];
}

- (void) addPingAnimation
{
    [UIView animateWithDuration:1.5 delay:0 options:(UIViewAnimationOptionRepeat) animations:^{
        CGAffineTransform scaleTransform = CGAffineTransformMakeScale(0.75, 0.75);
        self.transform = scaleTransform;
    }completion:^(BOOL finished)
     {
         [UIView animateWithDuration:1.5 animations:^{
             CGAffineTransform scaleTransform = CGAffineTransformMakeScale(20, 20);
             self.transform = scaleTransform;
         }];
     }];
    
    if(self.indefiniteAnimation){ //keep running animation indefinitely
        [self performSelectorOnMainThread:@selector(addPingAnimation) withObject:nil waitUntilDone:NO];
    }
}

- (void) addBlinkAnimation
{
    self.alpha = 0;
    [UIView animateWithDuration:1.5 delay:0 options:(UIViewAnimationOptionRepeat) animations:^{
        self.alpha = 1;
    }completion:^(BOOL finished)
     {
         [UIView animateWithDuration:1.5 animations:^{
             self.alpha = 0;
         }];
     }];
    
    if(self.indefiniteAnimation){ //keep running animation indefinitely
        [self performSelectorOnMainThread:@selector(addBlinkAnimation) withObject:nil waitUntilDone:NO];
    }
}

- (void) removeAnimations
{
    [self.layer removeAllAnimations];
    self.indefiniteAnimation = NO;
    [self removeFromSuperview];
}

- (void) addNoAnimation
{
    [NSTimer scheduledTimerWithTimeInterval:self.animationDuration target:self selector:@selector(removeAnimations) userInfo:nil repeats:YES];
}

- (void) addCustomAnimation: (CAAnimation *) animation
{
    [self.layer addAnimation:animation forKey:@"SKSplashAnimation"];
    [NSTimer scheduledTimerWithTimeInterval:self.animationDuration target:self selector:@selector(removeAnimations) userInfo:nil repeats:YES];
}

@end
