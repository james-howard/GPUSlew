//
//  MetalRenderer.m
//  GPUSlew
//
//  Created by James Howard on 1/16/18.
//  Copyright © 2018 James Howard. All rights reserved.
//

#import "MetalRenderer.h"

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <simd/simd.h>
#import <QuartzCore/QuartzCore.h>

#define SIZE 1024

struct Vertex {
    vector_float2 position;
    vector_float2 texCoords;
};

static void MakeUnitQuad(struct Vertex *v) {
    static struct Vertex vertices[] =
    {
        // Pixel Positions, Texture Coordinates
        { {  1.f,  0.f }, { 1.f, 1.f } },
        { {  0.f,  0.f }, { 0.f, 1.f } },
        { {  0.f,  1.f }, { 0.f, 0.f } },
        
        { {  1.f,  0.f }, { 1.f, 1.f } },
        { {  0.f,  1.f }, { 0.f, 0.f } },
        { {  1.f,  1.f }, { 1.f, 0.f } },
    };
    memcpy(v, vertices, sizeof(vertices));
}

@interface MetalRenderer () {
    id<MTLDevice> _device;
    id<MTLCommandQueue> _cmdQueue;
    id<MTLRenderPipelineState> _pipelineState;
    id<MTLTexture> _targetTexture;
}

@end

@implementation MetalRenderer

- (NSString *)gpuName {
    return _device.name;
}

- (void)setup {
    _device = CGDirectDisplayCopyCurrentMetalDevice(kCGDirectMainDisplay);
    NSLog(@"Using metal device %@", _device);
    _cmdQueue = [_device newCommandQueue];
    
    MTLTextureDescriptor *targetDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:SIZE height:SIZE mipmapped:NO];
    targetDesc.usage = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget;
    _targetTexture = [_device newTextureWithDescriptor:targetDesc];
    
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
    
    // Load the vertex function from the library
    id <MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertex_main"];
    
    // Load the fragment function from the library
    id <MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragment_main"];
    
    MTLRenderPipelineDescriptor *pipeDesc = [MTLRenderPipelineDescriptor new];
    pipeDesc.label = @"Simple Pipeline";
    pipeDesc.vertexFunction = vertexFunction;
    pipeDesc.fragmentFunction = fragmentFunction;
    pipeDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipeDesc.colorAttachments[0].blendingEnabled = NO;
    
    MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor vertexDescriptor];
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[0].offset = offsetof(struct Vertex, position);
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[1].bufferIndex = 0;
    vertexDescriptor.attributes[1].offset = offsetof(struct Vertex, texCoords);
    vertexDescriptor.layouts[0].stride = sizeof(struct Vertex);
    vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    
    pipeDesc.vertexDescriptor = vertexDescriptor;
    
    NSError *error = NULL;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipeDesc error:&error];
    NSAssert(_pipelineState != nil, nil);
}

- (void)teardown {
    _device = nil;
    _cmdQueue = nil;
    _pipelineState = nil;
    _targetTexture = nil;
}

- (void)reinitialize {
    [self teardown];
    [self setup];
}

- (void)renderWithCompletion:(void (^)(NSTimeInterval renderTime))completion {
    if (_device != CGDirectDisplayCopyCurrentMetalDevice(kCGDirectMainDisplay)) {
        [self reinitialize];
    }
    
    MTLRenderPassDescriptor *pass = [MTLRenderPassDescriptor new];
    pass.colorAttachments[0].loadAction = MTLLoadActionDontCare;
    pass.colorAttachments[0].storeAction = MTLStoreActionStore;
    pass.colorAttachments[0].texture = _targetTexture;
    
    id<MTLCommandBuffer> buf = [_cmdQueue commandBuffer];
    
    id <MTLRenderCommandEncoder> encoder = [buf renderCommandEncoderWithDescriptor:pass];
    encoder.label = @"Mandelbrot";
    [encoder setViewport:(MTLViewport){0.0, 0.0, (double)SIZE, (double)SIZE, -1.0, 1.0 }];
    [encoder setRenderPipelineState:_pipelineState];
    
    struct Vertex cursorVertices[6];
    MakeUnitQuad(cursorVertices);
    
    for (size_t i = 0; i < 6; i++) {
        struct Vertex *v = cursorVertices + i;
        v->position.x = 2.0 * v->position.x - 1.0;
        v->position.y = 2.0 * v->position.y - 1.0;
    }
    
    [encoder setVertexBytes:cursorVertices length:sizeof(cursorVertices) atIndex:0];
    
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [encoder endEncoding];
    
    NSTimeInterval start = CACurrentMediaTime();
    [buf addCompletedHandler:^(id<MTLCommandBuffer> abuf) {
        NSTimeInterval stop = CACurrentMediaTime();
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(stop-start);
        });
    }];
    [buf commit];
}

@end

