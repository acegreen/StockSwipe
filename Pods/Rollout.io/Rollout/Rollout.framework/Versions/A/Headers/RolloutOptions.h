//
// Created by Sergey Ilyevsky on 11/19/14.
// Copyright (c) 2014 DeDoCo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^RolloutTracker)(NSDictionary *data);

typedef enum {
    RolloutOptionsVerboseLevelSilent,
    RolloutOptionsVerboseLevelDebug
} RolloutOptionsVerboseLevel;

@interface RolloutOptions : NSObject

@property (nonatomic, copy) RolloutTracker tracker;
@property (nonatomic) BOOL disableSyncLoadingFallback;
@property (nonatomic) RolloutOptionsVerboseLevel verbose;
@property (nonatomic, strong) NSArray *silentFiles;
@property (nonatomic) BOOL rolloutDisabled;
@property (nonatomic, copy) NSArray *patchingDisabledClasses;
@property (nonatomic, strong) NSArray *blockedInJSClasses;
@end

