//
//  RolloutInvocationResult.h
//  Rollout
//
//  Created by Sergey Ilyevsky on 19/12/2016.
//  Copyright © 2016 DeDoCo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RolloutTypeWrapper.h"
#import "RolloutSwiftTypeWrapper.h"

@interface RolloutInvocationResult : NSObject

@property (nonatomic, readonly) RolloutTypeWrapper *returnValue;
@property (nonatomic, readonly) NSError *swiftError;

- (instancetype)initWithReturnValue:(RolloutTypeWrapper *)returnValue;
- (instancetype)initWithSwiftError:(NSError *)error;

@end
