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
    
    init(builtIn: JelloBuiltInNodeSubtype, inputPorts: [PortDefinition], outputPorts: [PortDefinition]){
        self.builtIn = builtIn
        self.inputPorts = inputPorts
        self.outputPorts = outputPorts
    }
    
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
    
    func setup(node: JelloNode)
    {
        let offset = JelloNode.getStandardInputPortPositionOffset(index: UInt8(0))
        let portModel = JelloInputPort(uuid: UUID(), index: UInt8(0), name: "OUT", dataType: .material, node: node, nodePositionX: node.positionX, nodePositionY: node.positionY, nodeOffsetX: Float(offset.x), nodeOffsetY: Float(offset.y))
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
        .add: JelloConstantFunctionNodeController(builtIn: .add, inputPorts: [PortDefinition(dataType: .anyFloat, name: "X"), PortDefinition(dataType: .anyFloat, name: "Y")], outputPorts: [PortDefinition(dataType: .anyFloat, name: "Z")]),
        .subtract: JelloConstantFunctionNodeController(builtIn: .subtract, inputPorts: [PortDefinition(dataType: .anyFloat, name: "X"), PortDefinition(dataType: .anyFloat, name: "Y")], outputPorts: [PortDefinition(dataType: .anyFloat, name: "Z")]),
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
