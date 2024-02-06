//
//  JelloCompilerTypeUtilities.swift
//  JelloCompilerStatic
//
//  Created by Natalie Cuthbert on 2023/12/26.
//

import Foundation
import SpirvMacros
import SpirvMacrosShared
import SPIRV_Headers_Swift

public func declareType(dataType: JelloConcreteDataType) -> UInt32 {
    switch dataType {
    case .bool:
        return #typeDeclaration(opCode: SpirvOpTypeBool)
    case .float:
        return #typeDeclaration(opCode: SpirvOpTypeFloat, [32])
    case .float2:
        let floatType = #typeDeclaration(opCode: SpirvOpTypeFloat, [32])
        return #typeDeclaration(opCode: SpirvOpTypeVector, [floatType, 2])
    case .float3:
        let floatType = #typeDeclaration(opCode: SpirvOpTypeFloat, [32])
        return #typeDeclaration(opCode: SpirvOpTypeVector, [floatType, 3])
    case .float4:
        let floatType = #typeDeclaration(opCode: SpirvOpTypeFloat, [32])
        return #typeDeclaration(opCode: SpirvOpTypeVector, [floatType, 4])
    case .int:
        return #typeDeclaration(opCode: SpirvOpTypeInt, [32, 1])
    default:
        fatalError("Type Not Supported Yet")
    }
}


public func declareNullValueConstant(dataType: JelloConcreteDataType) -> UInt32 {
    let typeId = declareType(dataType: dataType)
    let resultId = #id
    #globalDeclaration(opCode: SpirvOpConstantNull, [typeId, resultId])
    return resultId
}
