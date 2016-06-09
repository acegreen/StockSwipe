//
// Created by Sergey Ilyevsky on 1/11/15.
// Copyright (c) 2015 DeDoCo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    RolloutMethodId_methodType_class,
    RolloutMethodId_methodType_instance
} RolloutMethodId_methodType;

@interface RolloutMethodId : NSObject <NSCopying>

@property(readonly, nonatomic) NSString* clazz;
@property(readonly, nonatomic) NSString* selector;
@property(readonly, nonatomic) RolloutMethodId_methodType methodType;
@property(readonly, nonatomic) NSString *signature;

- (instancetype)initWithClass:(NSString *)clazz selector:(NSString *)selector methodType:(RolloutMethodId_methodType)methodType signature:(NSString *)signature;

- (instancetype)initFromJsonConfiguration:(NSDictionary *)json;

- (NSString *)dynamicCodeSelectorString;
@end

