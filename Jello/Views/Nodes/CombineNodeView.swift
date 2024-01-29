//
//  CombineNodeView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/29.
//
import Foundation
import SwiftData
import SwiftUI

struct CombineNodeView : View {
    private var node: JelloNode
    private var drawBounds: (inout Path) -> ()
    @Query private var nodeData: [JelloNodeData]
    @Query private var outputPorts: [JelloOutputPort]
    @Query private var inputPorts: [JelloInputPort]
    @Query private var outputEdges: [JelloEdge]

    init(node: JelloNode, drawBounds:  @escaping (inout Path) -> ()) {
        self.node = node
        self.drawBounds = drawBounds
        let nodeId = node.uuid
        self._nodeData = Query(filter: #Predicate<JelloNodeData> { data in data.node?.uuid == nodeId })
        self._outputPorts = Query(filter: #Predicate<JelloOutputPort> { data in data.node?.uuid == nodeId })
        self._inputPorts = Query(filter: #Predicate<JelloInputPort> { data in data.node?.uuid == nodeId }, sort: \.index)
    }
    
    var body: some View {
        guard let componentCountData = nodeData.filter({$0.key == JelloNodeDataKey.componentCount.rawValue}).first else {
            return AnyView(EmptyView())
        }
        
        guard case .int(let componentCount) = componentCountData.value else {
            return AnyView(EmptyView())
        }
        
        let sliderDisabled: Bool = nodeData.filter({$0.key == JelloNodeDataKey.typeSliderDisabled.rawValue}).first?.value == .some(.bool(true))

        return AnyView(ZStack {
            VStack {
                Text(node.name ?? "Unknown").font(.title2).minimumScaleFactor(0.2)
                    .bold()
                    .monospaced()
                    .foregroundStyle(.white)
                DiscreteSliderView(labels: ["v1", "v2", "v3", "v4"], fillPriors: true, fill: Gradient(colors: [.blue, .orange]), disabled: sliderDisabled, item: .init(get: {componentCount - 1}, set: {
                    value in
                    let prevComponentCount = componentCount
                    let nextComponentCount = value + 1
                    componentCountData.value = .int(nextComponentCount)
                    let nodeHeight: CGFloat = max(80 + JelloNode.headerHeight, JelloNode.getStandardNodeHeight(inputPortsCount: nextComponentCount, outputPortsCount: 1))
                    node.size = .init(width: node.size.width, height: nodeHeight)
                    let outputPort = outputPorts.first!
                    switch(value + 1) {
                    case 1:
                        outputPort.currentDataType = .float
                        outputPort.baseDataType = .float
                    case 2:
                        outputPort.currentDataType = .float2
                        outputPort.baseDataType = .float2
                    case 3:
                        outputPort.currentDataType = .float3
                        outputPort.baseDataType = .float3
                    case 4:
                        outputPort.currentDataType = .float4
                        outputPort.baseDataType = .float4
                    default:
                        fatalError("Unsupported component count")
                    }
                    
                    if nextComponentCount > prevComponentCount {
                        // Increase the number of input nodes
                        let indicesToName = ["x", "y", "z", "w"]
                        func makeInputPort(index: UInt8) -> JelloInputPort {
                            let position = JelloNode.getStandardInputPortPositionOffset(index: index)
                            return JelloInputPort(uuid: UUID(), index: index, name: indicesToName[Int(index)], dataType: .float, node: node, nodePositionX: node.positionX, nodePositionY: node.positionY, nodeOffsetX: Float(position.x), nodeOffsetY: Float(position.y))
                        }
                        try! node.modelContext?.transaction {
                            for index in prevComponentCount..<nextComponentCount {
                                let port = makeInputPort(index: UInt8(index))
                                node.modelContext?.insert(port)
                            }
                        }
                    } else {
                        // Decrease the number of input nodes, and delete associated edges
                        try! node.modelContext?.transaction {
                            for index in nextComponentCount..<prevComponentCount {
                                let inputPort = inputPorts[index]
                                if let edge = inputPort.edge {
                                    node.modelContext?.delete(edge)
                                }
                                node.modelContext?.delete(inputPort)
                            }
                        }
                    }
                    for i in inputPorts.indices {
                        let position = JelloNode.getStandardInputPortPositionOffset(index: UInt8(i))
                        inputPorts[i].nodeOffsetX = Float(position.x)
                        inputPorts[i].nodeOffsetY = Float(position.y)
                    }
                    
                })).frame(width: 200, height: 30).padding(5)
                Spacer(minLength: JelloNode.padding)
            }
            .padding(.all, JelloNode.padding)
        })
    }
}
