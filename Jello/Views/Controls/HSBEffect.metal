#include <metal_stdlib>
using namespace metal;


float3 hue2rgb(float hue) {
    hue = fract(hue); //only use fractional part of hue, making it loop
    float r = abs(hue * 6 - 3) - 1; //red
    float g = 2 - abs(hue * 6 - 2); //green
    float b = 2 - abs(hue * 6 - 4); //blue
    float3 rgb = float3(r,g,b); //combine components
    rgb = saturate(rgb); //clamp between 0 and 1
    return rgb;
}

float3 hsv2rgb(float3 hsv)
{
    float3 rgb = hue2rgb(hsv.x); //apply hue
    rgb = mix(1, rgb, hsv.y); //apply saturation
    rgb = rgb * hsv.z; //apply value
    return rgb;
}

float remap(float x, float startOld, float endOld, float startNew, float endNew) {
    float frac = (x - startOld) / (endOld - startOld);
    return startNew + (frac * (endNew - startNew));
}

[[ stitchable ]] half4 hsbEffect(float2 position, half4 color, float hue, float width) {
    // Calculate which square of the checkerboard we're in,
    // rounding values down.
    float2 pos = (position / width - float2(0.5 , 0.5)) * 2;
    
    float u = pos.x * sqrt( 1 - ( pos.y * pos.y ) / 2 );
    float v = pos.y * sqrt( 1 - ( pos.x * pos.x ) / 2 );
    
    float3 result = hsv2rgb(float3(hue, remap(u, -1, 1, 0, 1), remap(v, -1, 1, 1, 0)));
    half4 resultHalf = half4(result.x, result.y, result.z, 1);
    return  color.a * resultHalf;
}
