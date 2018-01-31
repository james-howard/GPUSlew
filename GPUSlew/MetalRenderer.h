//
//  MetalRenderer.h
//  GPUSlew
//
//  Created by James Howard on 1/16/18.
//  Copyright © 2018 James Howard. All rights reserved.
//

#import <Foundation/Foundation.h>

// Just renders a simple quad.
@interface MetalRenderer : NSObject

- (void)renderWithCompletion:(void (^)(NSTimeInterval renderTime))completion;

@property (readonly) NSString *gpuName;

@end
