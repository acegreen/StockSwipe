//
// Created by Sergey Ilyevsky on 27/07/2016.
// Copyright (c) 2016 DeDoCo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RolloutTweakId;
@class RolloutInvocation;


@interface RolloutSwiftTweakData : NSObject

@property (nonatomic, readonly) RolloutTweakId *tweakId;
@property (nonatomic, readonly) RolloutInvocation *invocation;
@property () BOOL shouldPatchInTheCurrentThread;

- (instancetype)initWithTweakId:(RolloutTweakId *)tweakId invocation:(RolloutInvocation *)invocation;


@end