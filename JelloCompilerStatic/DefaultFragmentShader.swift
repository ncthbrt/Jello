//
//  RenderingSharedTypes.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/04.
//

import SPIRV_Headers_Swift
import SpirvMacrosShared
import SpirvMacros
import simd

@SpirvStruct
public struct FrameData {
    // Per-frame constants.
    var projectionMatrix : matrix_float4x4 // 0, 0
    var projectionMatrixInv : matrix_float4x4 // 1, 64
    var viewMatrix: matrix_float4x4 // 2, 64
    var viewMatrixInv: matrix_float4x4 // 3, 64
    var depthUnproject: vector_float2 // 4, 64
    var screenToViewSpace: vector_float3 // 5, 8
    
    // Per-mesh constants.
    var modelViewMatrix : matrix_float4x4 // 6, 12
    var normalMatrix: matrix_float3x3 // 7, 64
    var modelMatrix : matrix_float4x4 // 8, 36
    
    // Per-light properties.
    var ambientLightColor: vector_float3 // 9, 64
    var directionalLightDirection : vector_float3 // 10, 12
    var directionalLightColor: vector_float3 // 12, 12
    var framebufferWidth: UInt32 // 12, 12
    var framebufferHeight : UInt32 // 13, 4
}



public let defaultFragmentShader: [UInt32] = #document({
    let vertexEntryPoint = #id
    #capability(opCode: SpirvOpCapability, [SpirvCapabilityShader.rawValue])
    let glsl450Id = #id
    #extInstImport(opCode: SpirvOpExtInstImport, [glsl450Id], #stringLiteral("GLSL.std.450"))
    #memoryModel(opCode: SpirvOpMemoryModel, [SpirvAddressingModelLogical.rawValue, SpirvMemoryModelGLSL450.rawValue])
    let typeVoid = #typeDeclaration(opCode: SpirvOpTypeVoid)
    
    let frameDataTypeId = FrameData.register()
    let (frameDataPointerTypeId, createFrameDataVariable) = FrameData.registerPointerType(storageClass: SpirvStorageClassUniformConstant)
    
    let frameDataId = createFrameDataVariable()
    #debugNames(opCode: SpirvOpName, [frameDataId], #stringLiteral("frameData"))
    #annotation(opCode: SpirvOpDecorate, [frameDataTypeId, SpirvDecorationBlock.rawValue])
    var frameDataOffset: UInt32 = 0
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 0, SpirvDecorationOffset.rawValue, frameDataOffset])
    frameDataOffset += 64
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 1, SpirvDecorationOffset.rawValue, frameDataOffset])
    frameDataOffset += 64
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 2, SpirvDecorationOffset.rawValue, frameDataOffset])
    frameDataOffset += 64
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 3, SpirvDecorationOffset.rawValue, frameDataOffset])
    frameDataOffset += 64
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 4, SpirvDecorationOffset.rawValue, frameDataOffset])
    frameDataOffset += 16
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 5, SpirvDecorationOffset.rawValue, frameDataOffset])
    frameDataOffset += 16
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 6, SpirvDecorationOffset.rawValue, frameDataOffset])
    frameDataOffset += 64
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 7, SpirvDecorationOffset.rawValue, frameDataOffset])
    frameDataOffset += 48
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 8, SpirvDecorationOffset.rawValue, frameDataOffset])
    frameDataOffset += 64
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 9, SpirvDecorationOffset.rawValue, frameDataOffset])
    frameDataOffset += 16
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 10, SpirvDecorationOffset.rawValue, frameDataOffset])
    frameDataOffset += 16
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 11, SpirvDecorationOffset.rawValue, frameDataOffset])
    frameDataOffset += 16
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 12, SpirvDecorationOffset.rawValue, frameDataOffset])
    frameDataOffset += 4
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 13, SpirvDecorationOffset.rawValue, frameDataOffset])
    // Matrix strides for Frame Data
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 0, SpirvDecorationMatrixStride.rawValue, 16])
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 1, SpirvDecorationMatrixStride.rawValue, 16])
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 2, SpirvDecorationMatrixStride.rawValue, 16])
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 3, SpirvDecorationMatrixStride.rawValue, 16])
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 6, SpirvDecorationMatrixStride.rawValue, 16])
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 7, SpirvDecorationMatrixStride.rawValue, 16])
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 8, SpirvDecorationMatrixStride.rawValue, 16])
    // Matrix Layout for Frame Data
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 0, SpirvDecorationRowMajor.rawValue])
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 1, SpirvDecorationRowMajor.rawValue])
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 2, SpirvDecorationRowMajor.rawValue])
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 3, SpirvDecorationRowMajor.rawValue])
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 6, SpirvDecorationRowMajor.rawValue])
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 7, SpirvDecorationRowMajor.rawValue])
    #annotation(opCode: SpirvOpMemberDecorate, [frameDataTypeId, 8, SpirvDecorationRowMajor.rawValue])
    
    #annotation(opCode: SpirvOpDecorate, [frameDataId, SpirvDecorationDescriptorSet.rawValue, 0])
//    #annotation(opCode: SpirvOpDecorate, [frameDataId, SpirvDecorationBinding.rawValue, 3])
    #annotation(opCode: SpirvOpDecorate, [frameDataId, SpirvDecorationNonWritable.rawValue])

    let intTypeId = declareType(dataType: .int)

    let float4TypeId = declareType(dataType: .float4)
    let float3TypeId = declareType(dataType: .float3)
    let float2TypeId = declareType(dataType: .float2)
    

    let float4x4TypeId = #typeDeclaration(opCode: SpirvOpTypeMatrix, [float4TypeId, 4])
    let float4x4UniformPointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassUniformConstant.rawValue, float4x4TypeId])

    let float4InputPointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassInput.rawValue, float4TypeId])
    
    let float3InputPointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassInput.rawValue, float3TypeId])
    
    let float2InputPointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassInput.rawValue, float2TypeId])
    
    
    let float4OutputPointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassOutput.rawValue, float4TypeId])
    let float3OutputPointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassOutput.rawValue, float3TypeId])
    let float2OutputPointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassOutput.rawValue, float2TypeId])
    

    // Vertex position
    let positionInId = #id
    #globalDeclaration(opCode: SpirvOpVariable, [float4InputPointerTypeId, positionInId, SpirvStorageClassInput.rawValue])
    #debugNames(opCode: SpirvOpName, [positionInId], #stringLiteral("position"))
    #annotation(opCode: SpirvOpDecorate, [positionInId, SpirvDecorationLocation.rawValue, 0])

    // Vertex tex-coord
    let texCoordInId = #id
    #globalDeclaration(opCode: SpirvOpVariable, [float2InputPointerTypeId, texCoordInId, SpirvStorageClassInput.rawValue])
    #debugNames(opCode: SpirvOpName, [texCoordInId], #stringLiteral("texCoord"))
    #annotation(opCode: SpirvOpDecorate, [texCoordInId, SpirvDecorationLocation.rawValue, 1])

    // Vertex Normal
    let normalInId = #id
    #globalDeclaration(opCode: SpirvOpVariable, [float3InputPointerTypeId, normalInId, SpirvStorageClassInput.rawValue])
    #debugNames(opCode: SpirvOpName, [normalInId], #stringLiteral("normal"))
    #annotation(opCode: SpirvOpDecorate, [normalInId, SpirvDecorationLocation.rawValue, 2])
    
    // Vertex Tangent
    let tangentInId = #id
    #globalDeclaration(opCode: SpirvOpVariable, [float3InputPointerTypeId, tangentInId, SpirvStorageClassInput.rawValue])
    #debugNames(opCode: SpirvOpName, [tangentInId], #stringLiteral("tangent"))
    #annotation(opCode: SpirvOpDecorate, [tangentInId, SpirvDecorationLocation.rawValue, 3])

    
    let bitangentInId = #id
    #globalDeclaration(opCode: SpirvOpVariable, [float3InputPointerTypeId, bitangentInId, SpirvStorageClassInput.rawValue])
    #debugNames(opCode: SpirvOpName, [bitangentInId], #stringLiteral("bitangent"))
    #annotation(opCode: SpirvOpDecorate, [bitangentInId, SpirvDecorationLocation.rawValue, 4])

    
    // Position Out
    let positionOutId = #id
    #globalDeclaration(opCode: SpirvOpVariable, [float4OutputPointerTypeId, positionOutId, SpirvStorageClassOutput.rawValue])
    #annotation(opCode: SpirvOpDecorate, [positionOutId, SpirvDecorationBuiltIn.rawValue, SpirvBuiltInPosition.rawValue])
    
    // World Pos Out
    let worldPosOutId = #id
    #globalDeclaration(opCode: SpirvOpVariable, [float4OutputPointerTypeId, worldPosOutId, SpirvStorageClassOutput.rawValue])
    #debugNames(opCode: SpirvOpName, [worldPosOutId], #stringLiteral("worldPos"))
    #annotation(opCode: SpirvOpDecorate, [worldPosOutId, SpirvDecorationLocation.rawValue, 1])

    // TexCoord Out
    let texCoordOutId = #id
    #globalDeclaration(opCode: SpirvOpVariable, [float2OutputPointerTypeId, texCoordOutId, SpirvStorageClassOutput.rawValue])
    #debugNames(opCode: SpirvOpName, [texCoordOutId], #stringLiteral("texCoord"))
    #annotation(opCode: SpirvOpDecorate, [texCoordOutId, SpirvDecorationLocation.rawValue, 2])
    // Tangent Out
    let tangentOutId = #id
    #globalDeclaration(opCode: SpirvOpVariable, [float3OutputPointerTypeId, tangentOutId, SpirvStorageClassOutput.rawValue])
    #debugNames(opCode: SpirvOpName, [tangentOutId], #stringLiteral("tangent"))
    #annotation(opCode: SpirvOpDecorate, [tangentOutId, SpirvDecorationLocation.rawValue, 3])
    
    // Bitangent Out
    let bitangentOutId = #id
    #globalDeclaration(opCode: SpirvOpVariable, [float3OutputPointerTypeId, bitangentOutId, SpirvStorageClassOutput.rawValue])
    #debugNames(opCode: SpirvOpName, [bitangentOutId], #stringLiteral("bitangent"))
    #annotation(opCode: SpirvOpDecorate, [bitangentOutId, SpirvDecorationLocation.rawValue, 4])
    
    // Normal Out
    let normalOutId = #id
    #globalDeclaration(opCode: SpirvOpVariable, [float3OutputPointerTypeId, normalOutId, SpirvStorageClassOutput.rawValue])
    #debugNames(opCode: SpirvOpName, [normalOutId], #stringLiteral("normal"))
    #annotation(opCode: SpirvOpDecorate, [normalOutId, SpirvDecorationLocation.rawValue, 5])
    
    
    #entryPoint(opCode: SpirvOpEntryPoint, [SpirvExecutionModelVertex.rawValue], [vertexEntryPoint], #stringLiteral("vertexMain"), [positionInId, texCoordInId, normalInId, tangentInId, bitangentInId, frameDataId, positionOutId, worldPosOutId, texCoordOutId, tangentOutId, bitangentOutId, normalOutId])
    
    let typeVertexFunction = #typeDeclaration(opCode: SpirvOpTypeFunction, [typeVoid])
    #functionHead(opCode: SpirvOpFunction, [typeVoid, vertexEntryPoint, 0, typeVertexFunction])
    #functionHead(opCode: SpirvOpLabel, [#id])
    
    #functionBody(opCode: SpirvOpCopyMemory, [texCoordOutId, texCoordInId])
    
    let positionInLoadId = #id
    #functionBody(opCode: SpirvOpLoad, [float4TypeId, positionInLoadId, positionInId])
    
    let modelMatrixInPtrId = #id
    let modelMatrixInLoadId = #id
    
    let modelMatrixIndexId = #id
    #globalDeclaration(opCode: SpirvOpConstant, [intTypeId, modelMatrixIndexId], int(8))
    #functionBody(opCode: SpirvOpAccessChain, [float4x4UniformPointerTypeId, modelMatrixInPtrId, frameDataId, modelMatrixIndexId])
    #functionBody(opCode: SpirvOpLoad, [float4x4TypeId, modelMatrixInLoadId, modelMatrixInPtrId])
    
    let worldPositionId = #id
    #functionBody(opCode: SpirvOpMatrixTimesVector, [float4TypeId, worldPositionId, modelMatrixInLoadId, positionInLoadId])
    #functionBody(opCode: SpirvOpStore, [worldPosOutId, worldPositionId])

    #functionBody(opCode: SpirvOpReturn)
    #functionBody(opCode: SpirvOpFunctionEnd)
    
    SpirvFunction.instance.writeFunction()
})
