//
//  SKSplashIcon.h
//  SKSplashView
//
//  Created by Sachin Kesiraju on 10/25/14.
//  Copyright (c) 2014 Sachin Kesiraju. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SKSplashView.h"

typedef NS_ENUM(NSInteger, SKIconAnimationType)
{
    SKIconAnimationTypeBounce,
    SKIconAnimationTypeGrow,
    SKIconAnimationTypeShrink,
    SKIconAnimationTypeFade,
    SKIconAnimationTypePing, //supports network dependent animation
    SKIconAnimationTypeBlink, //supports network dependent animation
    SKIconAnimationTypeNone,
    SKIconAnimationTypeCustom
};

@interface SKSplashIcon : UIImageView

@property (strong, nonatomic) UIColor *iconColor; //Default: white
@property (nonatomic, assign) CGSize iconSize;
@property (readonly, assign) SKIconAnimationType preAnimationType;
@property (readonly, assign) SKIconAnimationType postAnimationType;

- (instancetype) initWithImage: (UIImage *) iconImage;
- (instancetype) initWithImage: (UIImage *) iconImage animationType: (SKIconAnimationType) animationType;
- (instancetype) initWithImage:(UIImage *)iconImage initialSize:(CGSize)initialSize preAnimationType:(SKIconAnimationType)preAnimationType postAnimationType:(SKIconAnimationType)postAnimationType;


- (void) setIconAnimationType: (SKIconAnimationType) preAnimationType;
- (void) setIconPostAnimationType: (SKIconAnimationType) postAnimationType;
- (void) setCustomAnimation: (CAAnimation *) animation;

- (void) startAnimation: (SKIconAnimationType *) animationType;
- (void) startAnimationWithDuration: (SKIconAnimationType *) animationType: (CGFloat) animationDuration;

@end
