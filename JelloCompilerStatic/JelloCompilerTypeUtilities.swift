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
    case .slabMaterial:
        fatalError("Type Not Supported Yet")
    case .texture1d:
        fatalError("Type Not Supported Yet")
    case .texture2d:
        fatalError("Type Not Supported Yet")
    case .texture3d:
        fatalError("Type Not Supported Yet")
    }
}
