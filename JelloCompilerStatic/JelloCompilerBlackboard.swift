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

    public static var modelPosId: UInt32 = 0
    public static var worldPosId: UInt32 = 0
    public static var texCoordId: UInt32 = 0
    public static var tangentId: UInt32 = 0
    public static var bitangentId: UInt32 = 0
    public static var normalId: UInt32 = 0
    
    
    
    public static var glsl450ExtId : UInt32 = 0
    public static var gl_GlobalInvocationID: UInt32 = 0
    
    public static var outputComputeTexture: SpirvTextureBinding? = nil
    public static var inputComputeTextures: [SpirvTextureBinding] = []
    public static var entryPointInterfaceIds: [UInt32] = []
    

    public static var requireModelPos: Bool = false
    public static var requireWorldPos: Bool = false
    public static var requireTexCoordinates: Bool = false
    public static var requireTangent: Bool = false
    public static var requireBitangent: Bool = false
    public static var requireNormal: Bool = false

    public static func clear(){
        fragOutputColorId = 0
        frameDataId = 0
        worldPosId = 0
        texCoordId = 0
        tangentId = 0
        bitangentId = 0
        normalId = 0
        glsl450ExtId = 0
        gl_GlobalInvocationID = 0
        outputComputeTexture = nil
        inputComputeTextures = []
        entryPointInterfaceIds = []
        requireTexCoordinates = false
        requireWorldPos = false
        requireTangent = false
        requireBitangent = false
        requireNormal = false
        requireModelPos = false
    }
}
