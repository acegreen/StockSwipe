//
// Created by Sergey Ilyevsky on 8/23/15.
// Copyright (c) 2015 DeDoCo. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RolloutMethodId;
@class RolloutSwiftDevModeDataProvider;

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

typedef enum {
    RolloutTweakId_swiftSwizzlingMechanism_vtable,
    RolloutTweakId_swiftSwizzlingMechanism_codeInjection,
    RolloutTweakId_swiftSwizzlingMechanismsCount
} RolloutTweakId_swiftSwizzlingMechanism;

@interface RolloutTweakId : NSObject <NSCopying>

@property (readonly) id<RolloutMethodId> methodId;
@property (readonly) RolloutTweakId_swizzlingType swizzlingType;
@property (readonly) RolloutTweakId_closureType closureType;
@property (readonly) RolloutTweakId_swiftSwizzlingMechanism swiftSwizzlingMechanism;

- (instancetype)initWithMethodId:(id <RolloutMethodId>)methodId swizzlingType:(RolloutTweakId_swizzlingType)swizzlingType closureType:(RolloutTweakId_closureType)closureType swiftSwizzlingMechanism:(RolloutTweakId_swiftSwizzlingMechanism)swiftSwizzlingMechanism;

- (instancetype)initFromJsonConfiguration:(NSDictionary *)configuration swiftDevModeDataProvider:(RolloutSwiftDevModeDataProvider *)swiftDevModeDataProvider;

@end
