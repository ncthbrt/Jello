//
//  JelloNodeControllers.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/14.
//

import Foundation
import SwiftData
import SwiftUI



protocol JelloNodeController {
    func setup(node: JelloNode)
    func migrate(node: JelloNode)
    func onInputPortConnected(port: JelloInputPort, edge: JelloEdge)
    func onOutputPortConnected(port: JelloOutputPort, edge: JelloEdge)
    func onInputPortDisconnected(port: JelloInputPort, edge: JelloEdge)
    func onOutputPortDisconnected(port: JelloInputPort, edge: JelloEdge)
    var category: JelloNodeCategory { get }
    @ViewBuilder func body(node: JelloNode, drawBounds: @escaping (inout Path) -> ()) -> AnyView
}


private class JelloMaterialNodeController: JelloNodeController {
    

    func setup(node: JelloNode)
    {
        
    }
    
    
    func migrate(node: JelloNode) {
        
    }

    func onInputPortConnected(port: JelloInputPort, edge: JelloEdge)
    {
        
    }
    
    func onOutputPortConnected(port: JelloOutputPort, edge: JelloEdge)
    {
        
    }
    
    func onInputPortDisconnected(port: JelloInputPort, edge: JelloEdge)
    {
        
    }
    
    func onOutputPortDisconnected(port: JelloInputPort, edge: JelloEdge)
    {
        
    }
    
    var category: JelloNodeCategory { .other }
    
    
    @ViewBuilder func body(node: JelloNode, drawBounds: (inout Path) -> ()) -> AnyView {
        AnyView(EmptyView())
    }
    
}


fileprivate class JelloUserFunctionNodeController: JelloNodeController {
    init(){}
    
    func setup(node: JelloNode)
    {
        
    }
    
    
    func migrate(node: JelloNode) {
        
    }

    
    func onInputPortConnected(port: JelloInputPort, edge: JelloEdge)
    {
        
    }
    
    func onOutputPortConnected(port: JelloOutputPort, edge: JelloEdge)
    {
        
    }
    
    func onInputPortDisconnected(port: JelloInputPort, edge: JelloEdge)
    {
        
    }
    
    func onOutputPortDisconnected(port: JelloInputPort, edge: JelloEdge)
    {
        
    }
    
    var category: JelloNodeCategory { .other }
    
    func body(node: JelloNode, drawBounds: (inout Path) -> ()) -> AnyView {
        AnyView(EmptyView())
    }
}

struct PortDefinition {
    let dataType: JelloGraphDataType
    let name: String
}

fileprivate class JelloConstantFunctionNodeController: JelloNodeController {
    let builtIn: JelloBuiltInNodeSubtype
    let inputPorts: [PortDefinition]
    let outputPorts: [PortDefinition]
    
    init(builtIn: JelloBuiltInNodeSubtype, category: JelloNodeCategory, inputPorts: [PortDefinition], outputPorts: [PortDefinition]){
        self.builtIn = builtIn
        self.inputPorts = inputPorts
        self.outputPorts = outputPorts
        self.category = category
    }
    
    var category: JelloNodeCategory

    func setup(node: JelloNode)
    {
        for i in 0..<inputPorts.count {
            let port = inputPorts[i]
            
            let offset = JelloNode.getStandardInputPortPositionOffset(index: UInt8(i))
            let portModel = JelloInputPort(uuid: UUID(), index: UInt8(i), name: port.name, dataType: port.dataType, node: node, nodePositionX: node.positionX, nodePositionY: node.positionY, nodeOffsetX: Float(offset.x), nodeOffsetY: Float(offset.y))
            node.modelContext?.insert(portModel)
        }
        
        for i in 0..<outputPorts.count {
            let port = outputPorts[i]
            let offset = JelloNode.getStandardOutputPortPositionOffset(index: UInt8(i))
            let portModel = JelloOutputPort(uuid: UUID(), index: UInt8(i), name: port.name, dataType: port.dataType, node: node, edges: [], nodePositionX: node.positionX, nodePositionY: node.positionY, nodeOffsetX: Float(offset.x), nodeOffsetY: Float(offset.y))
            node.modelContext?.insert(portModel)
        }
        
        node.size = CGSize(width: JelloNode.standardNodeWidth, height: JelloNode.getStandardNodeHeight(inputPortsCount: inputPorts.count, outputPortsCount: outputPorts.count))
    }
    
    func migrate(node: JelloNode) {
        // TODO: Write migration script
    }
    
    func onInputPortConnected(port: JelloInputPort, edge: JelloEdge)
    {
        
    }
    
    func onOutputPortConnected(port: JelloOutputPort, edge: JelloEdge)
    {
        
    }
    
    func onInputPortDisconnected(port: JelloInputPort, edge: JelloEdge)
    {
        
    }
    
    func onOutputPortDisconnected(port: JelloInputPort, edge: JelloEdge)
    {
        
    }
    

    
    @ViewBuilder func body(node: JelloNode, drawBounds: @escaping (inout Path) -> ()) -> AnyView {
        AnyView(
            VStack {
                Text(node.name ?? "Unknown").font(.title2).minimumScaleFactor(0.2)
                    .bold()
                    .monospaced()
                Spacer()
            }
                .padding(.all, JelloNode.padding)
        )
    }
}



fileprivate class JelloOutputNodeController: JelloNodeController {
    init(){}
    
    var category: JelloNodeCategory { .material }
    
    func setup(node: JelloNode)
    {
        let offset = JelloNode.getStandardInputPortPositionOffset(index: UInt8(0))
        let portModel = JelloInputPort(uuid: UUID(), index: UInt8(0), name: "", dataType: .anyMaterial, node: node, nodePositionX: node.positionX, nodePositionY: node.positionY, nodeOffsetX: Float(offset.x), nodeOffsetY: Float(offset.y))
        node.modelContext?.insert(portModel)
        node.size = CGSize(width: JelloNode.standardNodeWidth, height: JelloNode.standardNodeWidth)
    }
    
    func migrate(node: JelloNode) {
        // TODO: Write migration script
    }
    
    func onInputPortConnected(port: JelloInputPort, edge: JelloEdge)
    {
        
    }
    
    func onOutputPortConnected(port: JelloOutputPort, edge: JelloEdge)
    {
        
    }
    
    func onInputPortDisconnected(port: JelloInputPort, edge: JelloEdge)
    {
        
    }
    
    func onOutputPortDisconnected(port: JelloInputPort, edge: JelloEdge)
    {
        
    }
    
    @ViewBuilder func body(node: JelloNode, drawBounds: @escaping (inout Path) -> ()) -> AnyView {
        AnyView(
            ZStack {
                GeometryReader { geometry in
                    Path(drawBounds).fill(ImagePaint(image: Image("FakeTestRender").resizable(), scale: geometry.size.width/1024))
                }
                Path(drawBounds).fill(Gradient(colors: [.black.opacity(0.3), .clear]))
                VStack {
                    Text("Preview").font(.title2).minimumScaleFactor(0.2)
                        .bold()
                        .monospaced()
                    Spacer()
                }.padding(.all, JelloNode.padding)
            }
        )
    }
}


fileprivate class JelloPreviewNodeController: JelloNodeController {
    init(){}
    
    var category: JelloNodeCategory { .utility }
    
    func setup(node: JelloNode)
    {
        let inputPortOffset = JelloNode.getStandardInputPortPositionOffset(index: UInt8(0))
        let inputPortModel = JelloInputPort(uuid: UUID(), index: UInt8(0), name: "", dataType: .any, node: node, nodePositionX: node.positionX, nodePositionY: node.positionY, nodeOffsetX: Float(inputPortOffset.x), nodeOffsetY: Float(inputPortOffset.y))
        node.modelContext?.insert(inputPortModel)
        
        let outputPortOffset = JelloNode.getStandardOutputPortPositionOffset(index: UInt8(0))
        let outputPortModel = JelloOutputPort(uuid: UUID(), index: UInt8(0), name: "", dataType: .any, node: node, edges: [], nodePositionX: node.positionX, nodePositionY: node.positionY, nodeOffsetX: Float(outputPortOffset.x), nodeOffsetY: Float(outputPortOffset.y))
        node.modelContext?.insert(outputPortModel)

        node.size = CGSize(width: JelloNode.standardNodeWidth, height: JelloNode.standardNodeWidth)
    }
    
    func migrate(node: JelloNode) {
        // TODO: Write migration script
    }
    
    func onInputPortConnected(port: JelloInputPort, edge: JelloEdge)
    {
        
    }
    
    func onOutputPortConnected(port: JelloOutputPort, edge: JelloEdge)
    {
        
    }
    
    func onInputPortDisconnected(port: JelloInputPort, edge: JelloEdge)
    {
        
    }
    
    func onOutputPortDisconnected(port: JelloInputPort, edge: JelloEdge)
    {
        
    }
    
    @ViewBuilder func body(node: JelloNode, drawBounds: @escaping (inout Path) -> ()) -> AnyView {
        AnyView(
            ZStack {
                GeometryReader { geometry in
                    Path(drawBounds).fill(ImagePaint(image: Image("FakeTestRender").resizable(), scale: geometry.size.width/1024))
                }
                Path(drawBounds).fill(Gradient(colors: [.black.opacity(0.3), .clear]))
                VStack {
                    Text("Output").font(.title2).minimumScaleFactor(0.2)
                        .bold()
                        .monospaced()
                    Spacer()
                }.padding(.all, JelloNode.padding)
            }
        )
    }
}


struct JelloNodeControllerFactory {
    private static let materialNodeController : any JelloNodeController = JelloMaterialNodeController()
    private static let userFunctionNodeController : any JelloNodeController = JelloUserFunctionNodeController()
    private static let builtinFunctionControllerMap: [JelloBuiltInNodeSubtype: any JelloNodeController] = [
        .materialOutput: JelloOutputNodeController(),
        .preview: JelloPreviewNodeController(),
        .slabShader: JelloConstantFunctionNodeController(builtIn: .slabShader, category: .material, inputPorts: [PortDefinition(dataType: .float3, name: "Albedo"), PortDefinition(dataType: .float, name: "F0"), PortDefinition(dataType: .float, name: "F90"), PortDefinition(dataType: .float, name: "Roughness"), PortDefinition(dataType: .float, name: "Anisotropy"), PortDefinition(dataType: .float3, name: "Normal"), PortDefinition(dataType: .float3, name: "Tangent"), PortDefinition(dataType: .float, name: "SSS MFP"), PortDefinition(dataType: .float, name: "SSS MFP Scale"), PortDefinition(dataType: .float, name: "SSS Phase Anisotropy"), PortDefinition(dataType: .float3, name: "Emissive Color"), PortDefinition(dataType: .float, name: "2nd Roughness"), PortDefinition(dataType: .float, name: "2nd Roughness Weight"), PortDefinition(dataType: .float, name: "Fuzz Roughness"), PortDefinition(dataType: .float3, name: "Fuzz Amount"), PortDefinition(dataType: .float3, name: "Fuzz Color"), PortDefinition(dataType: .float, name: "Glint Density"), PortDefinition(dataType: .float2, name: "Glint UVS")], outputPorts: [PortDefinition(dataType: .slabMaterial, name: "")]),
        .add: JelloConstantFunctionNodeController(builtIn: .add, category: .math, inputPorts: [PortDefinition(dataType: .anyFloat, name: "X"), PortDefinition(dataType: .anyFloat, name: "Y")], outputPorts: [PortDefinition(dataType: .anyFloat, name: "Z")]),
        .subtract: JelloConstantFunctionNodeController(builtIn: .subtract, category: .math, inputPorts: [PortDefinition(dataType: .anyFloat, name: "X"), PortDefinition(dataType: .anyFloat, name: "Y")], outputPorts: [PortDefinition(dataType: .anyFloat, name: "Z")]),
    ]


    static func getController(_ node: JelloNode) -> any JelloNodeController {
        switch node.type {
        case .builtIn(let f):
            return builtinFunctionControllerMap[f]!
        case .material(_):
            return materialNodeController
        case .userFunction(_):
            return userFunctionNodeController
        }
    }
}
