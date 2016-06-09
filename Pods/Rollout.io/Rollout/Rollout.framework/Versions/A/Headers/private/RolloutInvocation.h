//
// Created by Sergey Ilyevsky on 6/25/15.
// Copyright (c) 2015 DeDoCo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RolloutTypeWrapper;
@class RolloutConfiguration;
@class RolloutInvocationsListFactory;
@class RolloutTweakId;
@class RolloutDeviceProperties;
@class RolloutInvocationContext;

@protocol RolloutInvocation

- (RolloutTypeWrapper *)invokeWithContext:(RolloutInvocationContext *)context originalMethodWrapper:(RolloutTypeWrapper *(^)(NSArray *))originalMethodWrapper;

-(BOOL)rolloutDisabled;
-(void)setRolloutDisabled:(BOOL)value;

@end


@interface RolloutInvocation : NSObject <RolloutInvocation>

- (instancetype)initWithConfiguration:(RolloutConfiguration *)configuration listsFactory:(RolloutInvocationsListFactory *)listsFactory deviceProperties:(RolloutDeviceProperties *)deviceProperties;
@property (nonatomic) BOOL rolloutDisabled;

@end
