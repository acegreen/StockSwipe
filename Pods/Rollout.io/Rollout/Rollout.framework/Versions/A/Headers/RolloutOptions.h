//
// Created by Sergey Ilyevsky on 11/19/14.
// Copyright (c) 2014 DeDoCo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RolloutProxyInfo.h"

typedef void (^RolloutTracker)(NSDictionary * _Nonnull data);
typedef NSString * _Nonnull (^RolloutProxy)(RolloutProxyInfo* _Nonnull proxyInfo);

typedef enum {
    RolloutOptionsVerboseLevelSilent,
    RolloutOptionsVerboseLevelDebug
} RolloutOptionsVerboseLevel;

@interface RolloutOptions : NSObject

@property (nonatomic, copy, nullable) RolloutTracker tracker;
@property (nonatomic, copy, nullable) RolloutProxy proxy;
@property (nonatomic) BOOL disableSyncLoadingFallback;
@property (nonatomic) RolloutOptionsVerboseLevel verbose;
@property (nonatomic, strong) NSArray * _Nullable silentFiles;
@property (nonatomic) BOOL rolloutDisabled;
@property (nonatomic, copy) NSArray * _Nullable patchingDisabledClasses;
@property (nonatomic, strong) NSArray * _Nullable blockedInJSClasses;
@property (nonatomic, copy) NSString * _Nullable customSigningCertificate;

@end

