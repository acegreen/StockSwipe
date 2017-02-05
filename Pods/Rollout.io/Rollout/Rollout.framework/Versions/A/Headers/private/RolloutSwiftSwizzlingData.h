//
// Created by Sergey Ilyevsky on 08/12/2016.
// Copyright (c) 2016 DeDoCo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RolloutSwiftTweakData;
@class RolloutSwiftTweakData;


@interface RolloutSwiftSwizzlingData : NSObject

+ (RolloutSwiftSwizzlingData *)instance;

- (RolloutSwiftTweakData *)tweakDataForHash:(NSString *)hash;

- (void)setTweakData:(RolloutSwiftTweakData *)tweakData forHash:(NSString *)hash;
@end