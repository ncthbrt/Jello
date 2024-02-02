//
//  GridEffect.metal
//  Jello
//
//  Created by Natalie Cuthbert on 2024/02/01.
//

#include <metal_stdlib>
using namespace metal;



[[ stitchable ]] half4 gridEffect(float2 position, half4 color, half4 gridColor, float stepsX, float stepsY, float thicknessX, float thicknessY) {
    // Calculate which square of the checkerboard we're in,
    // rounding values down.
    if(fract((position.x) * stepsX) < thicknessX || fract((position.y) * stepsY) < thicknessY)
        return gridColor;
    else
        return color;
}
