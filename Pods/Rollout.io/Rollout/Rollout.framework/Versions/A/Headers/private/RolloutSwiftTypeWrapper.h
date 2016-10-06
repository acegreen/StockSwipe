//
//  RolloutSwiftTypeWrapper.h
//  Rollout
//
//  Created by Elad Cohen on 8/14/16.
//  Copyright © 2016 DeDoCo. All rights reserved.
//

@interface RolloutSwiftTypeWrapper : NSObject

@property (nonatomic, readonly) id object;
@property (nonatomic, readonly) NSString* className;

-(instancetype)initWithObject:(id)object className:(NSString*)className;

@end
