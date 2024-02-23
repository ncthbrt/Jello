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

public let defaultVertexShader: [UInt32] = #document({
    let vertexEntryPoint = #id
    #capability(opCode: SpirvOpCapability, [SpirvCapabilityShader.rawValue])
    let glsl450Id = #id
    #extInstImport(opCode: SpirvOpExtInstImport, [glsl450Id], #stringLiteral("GLSL.std.450"))
    #memoryModel(opCode: SpirvOpMemoryModel, [SpirvAddressingModelLogical.rawValue, SpirvMemoryModelGLSL450.rawValue])
    let typeVoid = #typeDeclaration(opCode: SpirvOpTypeVoid)
    
    let frameDataTypeId = FrameData.register()
    let (_, createFrameDataVariable) = FrameData.registerPointerType(storageClass: SpirvStorageClassUniformConstant)
    
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
    
    #annotation(opCode: SpirvOpDecorate, [frameDataId, SpirvDecorationDescriptorSet.rawValue, frameDataDescriptorSet])
    #annotation(opCode: SpirvOpDecorate, [frameDataId, SpirvDecorationBinding.rawValue, frameDataBinding])
    #annotation(opCode: SpirvOpDecorate, [frameDataId, SpirvDecorationNonWritable.rawValue])

    let intTypeId = declareType(dataType: .int)

    let float4TypeId = declareType(dataType: .float4)
    let float3TypeId = declareType(dataType: .float3)
    let float2TypeId = declareType(dataType: .float2)
    

    let float4x4TypeId = #typeDeclaration(opCode: SpirvOpTypeMatrix, [float4TypeId, 4])
    let float4x4UniformPointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassUniformConstant.rawValue, float4x4TypeId])

    let float3x3TypeId = #typeDeclaration(opCode: SpirvOpTypeMatrix, [float3TypeId, 3])
    let float3x3UniformPointerTypeId = #typeDeclaration(opCode: SpirvOpTypePointer, [SpirvStorageClassUniformConstant.rawValue, float3x3TypeId])

    
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

    let modelPositionOutId = #id
    #globalDeclaration(opCode: SpirvOpVariable, [float4OutputPointerTypeId, modelPositionOutId, SpirvStorageClassOutput.rawValue])
    #debugNames(opCode: SpirvOpName, [modelPositionOutId], #stringLiteral("modelPos"))
    #annotation(opCode: SpirvOpDecorate, [modelPositionOutId, SpirvDecorationLocation.rawValue, 0])

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
    #functionBody(opCode: SpirvOpVectorTimesMatrix, [float4TypeId, worldPositionId, positionInLoadId, modelMatrixInLoadId])
    #functionBody(opCode: SpirvOpStore, [worldPosOutId, worldPositionId])

    // Calculate position in clip space
    
    let projectionMatrixInPtrId = #id
    let projectionMatrixInLoadId = #id

    
    let projectionMatrixIndexId = #id
    #globalDeclaration(opCode: SpirvOpConstant, [intTypeId, projectionMatrixIndexId], int(0))
    #functionBody(opCode: SpirvOpAccessChain, [float4x4UniformPointerTypeId, projectionMatrixInPtrId, frameDataId, projectionMatrixIndexId])
    #functionBody(opCode: SpirvOpLoad, [float4x4TypeId, projectionMatrixInLoadId, projectionMatrixInPtrId])

    let modelViewMatrixInPtrId = #id
    let modelViewMatrixInLoadId = #id
    
    let modelViewMatrixIndexId = #id
    #globalDeclaration(opCode: SpirvOpConstant, [intTypeId, modelViewMatrixIndexId], int(6))
    #functionBody(opCode: SpirvOpAccessChain, [float4x4UniformPointerTypeId, modelViewMatrixInPtrId, frameDataId, modelViewMatrixIndexId])
    #functionBody(opCode: SpirvOpLoad, [float4x4TypeId, modelViewMatrixInLoadId, modelViewMatrixInPtrId])
    
    let positionTimesModelViewMatrixId = #id
    #functionBody(opCode: SpirvOpVectorTimesMatrix, [float4TypeId, positionTimesModelViewMatrixId, positionInLoadId, modelViewMatrixInLoadId])
    let clipSpacePositionId = #id
    #functionBody(opCode: SpirvOpVectorTimesMatrix, [float4TypeId, clipSpacePositionId, positionTimesModelViewMatrixId, projectionMatrixInLoadId])
    #functionBody(opCode: SpirvOpStore, [positionOutId, clipSpacePositionId])
    
    // Calculate the tangent, bitangent and normal in eye space.
    let normalMatrixInPtrId = #id
    let normalMatrixInLoadId = #id
    
    let normalMatrixIndexId = #id
    #globalDeclaration(opCode: SpirvOpConstant, [intTypeId, normalMatrixIndexId], int(7))
    #functionBody(opCode: SpirvOpAccessChain, [float3x3UniformPointerTypeId, normalMatrixInPtrId, frameDataId, normalMatrixIndexId])
    #functionBody(opCode: SpirvOpLoad, [float3x3TypeId, normalMatrixInLoadId, normalMatrixInPtrId])
    
    let tangentInLoadId = #id
    #functionBody(opCode: SpirvOpLoad, [float3TypeId, tangentInLoadId, tangentInId])

    let bitangentInLoadId = #id
    #functionBody(opCode: SpirvOpLoad, [float3TypeId, bitangentInLoadId, bitangentInId])
    
    let normalInLoadId = #id
    #functionBody(opCode: SpirvOpLoad, [float3TypeId, normalInLoadId, normalInId])

    let normalMatrixTimesNormalId = #id
    #functionBody(opCode: SpirvOpVectorTimesMatrix, [float3TypeId, normalMatrixTimesNormalId, normalInLoadId, normalMatrixInLoadId])
    
    let normalMatrixTimesTangentId = #id
    #functionBody(opCode: SpirvOpVectorTimesMatrix, [float3TypeId, normalMatrixTimesTangentId, tangentInLoadId, normalMatrixInLoadId])
    
    let normalMatrixTimesBitangentId = #id
    #functionBody(opCode: SpirvOpVectorTimesMatrix, [float3TypeId, normalMatrixTimesBitangentId, bitangentInLoadId, normalMatrixInLoadId])
    
    let normaliseNormalId = #id
    #functionBody(opCode: SpirvOpExtInst, [float3TypeId, normaliseNormalId, glsl450Id, GLSLstd450Normalize.rawValue, normalMatrixTimesNormalId])
    
    let normaliseTangentId = #id
    #functionBody(opCode: SpirvOpExtInst, [float3TypeId, normaliseTangentId, glsl450Id, GLSLstd450Normalize.rawValue, normalMatrixTimesTangentId])
    
    let normaliseBitangentId = #id
    #functionBody(opCode: SpirvOpExtInst, [float3TypeId, normaliseBitangentId, glsl450Id, GLSLstd450Normalize.rawValue, normalMatrixTimesBitangentId])

    let negateBitangentId = #id
    #functionBody(opCode: SpirvOpFNegate, [float3TypeId, negateBitangentId, normaliseBitangentId])
    
    #functionBody(opCode: SpirvOpStore, [normalOutId, normaliseNormalId])
    #functionBody(opCode: SpirvOpStore, [tangentOutId, normaliseTangentId])
    #functionBody(opCode: SpirvOpStore, [bitangentOutId, negateBitangentId])
    
    #functionBody(opCode: SpirvOpReturn)
    #functionBody(opCode: SpirvOpFunctionEnd)
    
    SpirvFunction.instance.writeFunction()
})
