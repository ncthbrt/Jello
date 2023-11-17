//
//  JelloNodeControllers.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/14.
//

import Foundation
import SwiftData

protocol JelloNodeController {
    func setup(node: JelloNode)
    func onInputPortConnected(port: JelloInputPort, edge: JelloEdge)
    func onOutputPortConnected(port: JelloOutputPort, edge: JelloEdge)
    func onInputPortDisconnected(port: JelloInputPort, edge: JelloEdge)
    func onOutputPortDisconnected(port: JelloInputPort, edge: JelloEdge)
}


private class JelloMaterialNodeController: JelloNodeController {
    init(){}
    
    func setup(node: JelloNode)
    {
        
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
}


fileprivate class JelloUserFunctionNodeController: JelloNodeController {
    init(){}
    
    func setup(node: JelloNode)
    {
        
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
            if !node.inputPorts.contains(where: { $0.name == port.name }) {
                let port = JelloInputPort(id: UUID(), index: UInt8(i), name: port.name, dataType: port.dataType, node: node)
                node.modelContext?.insert(port)
            }
        }
        
        for i in 0..<outputPorts.count {
            let port = outputPorts[i]
            if !node.outputPorts.contains(where: { $0.name == port.name }) {
                let port = JelloOutputPort(id: UUID(), index: UInt8(i), name: port.name, dataType: port.dataType, node: node, edges: [])
                node.modelContext?.insert(port)
            }
        }
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
}






struct JelloNodeControllerFactory {
    private static let materialNodeController : JelloNodeController = JelloMaterialNodeController()
    private static let userFunctionNodeController : JelloNodeController = JelloUserFunctionNodeController()
    private static let builtinFunctionControllerMap: [JelloBuiltInNodeSubtype: JelloNodeController] = [
        .add: JelloConstantFunctionNodeController(builtIn: .add, inputPorts: [PortDefinition(dataType: .anyFloat, name: "X"), PortDefinition(dataType: .anyFloat, name: "Y")], outputPorts: [PortDefinition(dataType: .anyFloat, name: "Z")]),
        .subtract: JelloConstantFunctionNodeController(builtIn: .subtract, inputPorts: [PortDefinition(dataType: .anyFloat, name: "X"), PortDefinition(dataType: .anyFloat, name: "Y")], outputPorts: [PortDefinition(dataType: .anyFloat, name: "Z")]),
    ]


    static func getController(_ node: JelloNode) -> JelloNodeController {
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
