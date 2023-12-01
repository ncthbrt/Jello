import SwiftUI


extension JelloNodeCategory {
    func getCategoryGradient() -> Gradient {
        switch self {
        case .math:
            return Gradient(colors: [.green, .blue])
        case .other:
            return Gradient(colors: [.yellow, .orange])
        case .utility:
            return Gradient(colors: [.blue, .orange])
        case .material:
            return Gradient(colors: [.blue, .purple])
        }
    }
}

extension JelloGraphDataType {
    func getTypeGradient() -> Gradient {
        switch self {
        case .bool:
            return Gradient(colors: [.purple, .teal])
        case .int:
            return Gradient(colors: [.red, .teal])
        case .float:
            return Gradient(colors: [.orange, .green])
        case .float2:
            return Gradient(colors: [.yellow, .green])
        case .float3:
            return Gradient(colors: [.red, .green])
        case .float4:
            return Gradient(colors: [.purple, .green])
        case .texture1d:
            return Gradient(colors: [.gray, .mint])
        case .texture2d:
            return Gradient(colors: [.cyan, .mint])
        case .texture3d:
            return Gradient(colors: [.indigo, .mint])
        case .any:
            return Gradient(colors: [.red, .yellow, .green, .blue])
        case .anyFloat:
            return Gradient(colors: [.green, .teal])
        case .anyTexture:
            return Gradient(colors: [.mint, .teal])
        case .anyMaterial:
            return Gradient(colors: [.blue, .purple])
        case .slabMaterial:
            return Gradient(colors: [.blue, .yellow])
        }
    }
    
    
    static func isPortTypeCompatible(edge: JelloGraphDataType, port: JelloGraphDataType) -> Bool {
        switch (edge, port) {
        case (_, .any):
            return true
        case (.any, _):
            return true
        case (let x, let y) where x == y:
            return true
        case (.float, .anyFloat):
            return true
        case (.float2, .anyFloat):
            return true
        case (.float3, .anyFloat):
            return true
        case (.float4, .anyFloat):
            return true
        case (.anyFloat, .float):
            return true
        case (.anyFloat, .float2):
            return true
        case (.anyFloat, .float3):
            return true
        case (.anyFloat, .float4):
            return true
        case (_, .anyFloat):
            return false
        case (.anyFloat, _):
            return false
        case (.texture1d, .anyTexture):
            return true
        case (.texture2d, .anyTexture):
            return true
        case (.texture3d, .anyTexture):
            return true
        case (.anyTexture, .texture1d):
            return true
        case (.anyTexture, .texture2d):
            return true
        case (.anyTexture, .texture3d):
            return true
        case (_, .anyTexture):
            return false
        case (.anyTexture, _):
            return false
        case (.anyMaterial, .slabMaterial):
            return true
        case (.slabMaterial, .anyMaterial):
            return true
        case (.anyMaterial, _):
            return false
        case (_, _):
            return false
        }
    }
    
    static func getMostSpecificType(a: JelloGraphDataType, b: JelloGraphDataType) -> JelloGraphDataType {
        switch (a, b) {
        case (let x, let y) where x == y:
            return x
        case (.any, let x):
            return x
        case (.anyFloat, let x):
            return x
        case (.anyTexture, let x):
            return x
        case (let x, .any):
            return x
        case (let x, .anyFloat):
            return x
        case (let x, .anyTexture):
            return x
        default:
            return a // Return first type as a tie breaker, both types are equally specific, so we need to choose one
        }
    }
    
}
