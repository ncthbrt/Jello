//
//  SwiftCompilerBlackboard.swift
//  JelloCompilerStatic
//
//  Created by Natalie Cuthbert on 2023/12/27.
//

import Foundation


public class JelloCompilerBlackboard {
    public static var fragOutputColorId : UInt32 = 0
    public static var frameDataId : UInt32 = 0
    
    public static var worldPosInId: UInt32 = 0
    public static var texCoordInId: UInt32 = 0
    public static var tangentInId: UInt32 = 0
    public static var bitangentInId: UInt32 = 0
    public static var normalInId: UInt32 = 0
    
    public static var glsl450ExtId : UInt32 = 0
    
    public static func clear(){
        fragOutputColorId = 0
        frameDataId = 0
        worldPosInId = 0
        texCoordInId = 0
        tangentInId = 0
        bitangentInId = 0
        normalInId = 0
        glsl450ExtId = 0
    }
}
