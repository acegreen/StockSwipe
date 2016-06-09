//
// Created by Sergey Ilyevsky on 8/23/15.
// Copyright (c) 2015 DeDoCo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RolloutMethodId;

typedef enum {
    RolloutTweakId_swizzlingType_replaceImplementation,
    RolloutTweakId_swizzlingType_createImplementation,
    RolloutTweakId_swizzlingTypesCount
} RolloutTweakId_swizzlingType;



@interface RolloutTweakId : NSObject <NSCopying>

@property (readonly) RolloutMethodId *methodId;
@property (readonly) RolloutTweakId_swizzlingType swizzlingType;


- (instancetype)initWithMethodId:(RolloutMethodId *)methodId swizzlingType:(RolloutTweakId_swizzlingType)swizzlingType;
- (instancetype)initFromJsonConfiguration:(NSDictionary*)configuration;

@end
