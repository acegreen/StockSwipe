//
// Created by Sergey Ilyevsky on 11/01/2017.
// Copyright (c) 2017 DeDoCo. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RolloutProxyInfo : NSObject

@property (readonly) NSString *originalURL;
@property (readonly) NSString *staticPrefix;
@property (readonly) NSString *dynamicPart;

- (instancetype)initWithOriginalURL:(NSString *)originalURL staticPrefix:(NSString *)staticPrefix dynamicPart:(NSString *)dynamicPart;

@end
