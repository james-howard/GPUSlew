//
//  Shader.metal
//  GPUSlew
//
//  Created by James Howard on 1/16/18.
//  Copyright © 2018 James Howard. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

struct Vertex
{
    float2 position [[attribute(0)]];
    float2 texCoords [[attribute(1)]];
};

struct ProjectedVertex
{
    float4 position [[position]];
    float2 texCoords;
};

// https://en.wikipedia.org/wiki/Mandelbrot_set
int mandelbrot(float2 c, int maxI = 500) {
    // scale c from { (0, 1), (0, 1) } to { (-2.5, 1.0), (-1.0, 1.0) }
    c.x *= 3.5;
    c.x -= 2.5;
    c.y *= 2.0;
    c.y -= 1.0;
    
    auto xy = float2(0.0, 0.0);
    int i = 0;
    while (i < maxI && length_squared(xy) < 4.0) {
        float xtemp = xy.x * xy.x - xy.y * xy.y + c.x;
        xy.y = 2.0 * xy.x * xy.y + c.y;
        xy.x = xtemp;
        i++;
    }
    return i;
}

vertex ProjectedVertex vertex_main(Vertex vert [[stage_in]])
{
    ProjectedVertex out;
    out.position = float4(vert.position.x, vert.position.y, 0.0, 1.0);
    out.texCoords = vert.texCoords;
    return out;
}

fragment float4 fragment_main(ProjectedVertex in [[stage_in]])
{
    int n = clamp(mandelbrot(in.texCoords), 0, 255);
    return float4((float)n / 255.0, 0, 0, 1);
}

