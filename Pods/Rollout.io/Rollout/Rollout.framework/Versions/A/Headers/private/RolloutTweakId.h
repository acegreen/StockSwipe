//
// Created by Sergey Ilyevsky on 8/23/15.
// Copyright (c) 2015 DeDoCo. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RolloutMethodId;

typedef enum {
    RolloutTweakId_swizzlingType_replaceImplementation,
    RolloutTweakId_swizzlingType_createImplementation,
    RolloutTweakId_swizzlingTypesCount
} RolloutTweakId_swizzlingType;

typedef enum {
    RolloutTweakId_closureType_objC,
    RolloutTweakId_closureType_swift,
    RolloutTweakId_closureTypesCount
} RolloutTweakId_closureType;

@interface RolloutTweakId : NSObject <NSCopying>

@property (readonly) id<RolloutMethodId> methodId;
@property (readonly) RolloutTweakId_swizzlingType swizzlingType;
@property (readonly) RolloutTweakId_closureType closureType;

- (instancetype)initWithMethodId:(id <RolloutMethodId>)methodId swizzlingType:(RolloutTweakId_swizzlingType)swizzlingType closureType:(RolloutTweakId_closureType)closureType;

- (instancetype)initFromJsonConfiguration:(NSDictionary *)configuration;

@end
