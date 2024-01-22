//
//  ColorExtensions.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/22.
//

import Foundation


func hue2rgb(hue: Float) -> simd_float3 {
    var h = max(0, min(1, hue))
    var r = abs(h * 6 - 3) - 1 //red
    var g = 2 - abs(h * 6 - 2) //green
    var b = 2 - abs(h * 6 - 4) //blue
    var rgb = simd_float3(r,g,b) //combine components
    return rgb.clamped(lowerBound: .zero, upperBound: .one)
}

func hsb2rgb(hsb: simd_float3) -> simd_float3 {
    var rgb = hue2rgb(hue: hsb.x) //apply hue
    rgb = mix(.one, rgb, t: hsb.y) //apply saturation
    rgb = rgb * hsb.z //apply value
    return rgb
}
