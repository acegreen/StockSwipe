//
//  Rollout SDK version 1.3.1, Build 257
//
//  Copyright (c) 2014 Rollout.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RolloutOptions.h"

@interface Rollout : NSObject

+(void)setupWithKey:(NSString *)rolloutKey;
+(void)setupWithKey:(NSString *)rolloutKey options:(RolloutOptions *)options;
+(BOOL)rolloutDisabled;
+(void)setRolloutDisabled:(BOOL)value;

+(void)setupWithKey:(NSString *)rolloutKey developmentDevice: (BOOL)developmentDevice __attribute__ ((deprecated));
+(void)setupWithKey:(NSString *)rolloutKey developmentDevice:(BOOL)developmentDevice options:(RolloutOptions*)options __attribute__ ((deprecated));

+(void) setupWithDebug: (BOOL) debug options:(RolloutOptions*)options __attribute__ ((deprecated));
+(void) setupWithDebug: (BOOL) debug __attribute__ ((deprecated));

@end

