//
//  SwizzleNodeView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/19.
//

import Foundation
import SwiftData
import SwiftUI

struct SwizzleNodeView : View {
    private var node: JelloNode
    @Query private var inputPorts: [JelloInputPort]
    @Query private var outputPorts: [JelloOutputPort]

    private var drawBounds: (inout Path) -> ()
    @Query private var nodeData: [JelloNodeData]
    
    init(node: JelloNode, drawBounds:  @escaping (inout Path) -> ()) {
        self.node = node
        self.drawBounds = drawBounds
        let nodeId = node.uuid
        self._nodeData = Query(filter: #Predicate<JelloNodeData> { data in data.node?.uuid == nodeId })
        self._inputPorts = Query(filter: #Predicate<JelloInputPort> { data in data.node?.uuid == nodeId })
        self._outputPorts = Query(filter: #Predicate<JelloOutputPort> { data in data.node?.uuid == nodeId })
    }
    
    private func getSelectorList() -> [String] {
        let inputPort = inputPorts.first!
        switch(inputPort.currentDataType) {
        case .float:
            return ["0", "x"]
        case .float2:
            return ["0", "x", "y"]
        case .float3:
            return ["0", "x", "y", "z"]
        case .float4:
            return ["0", "x", "y", "z", "w"]
        default:
            return ["0", "x"]
        }
    }
    
    var body: some View {
        guard let componentCountData = nodeData.filter({$0.key == JelloNodeDataKey.componentCount.rawValue}).first else {
            return AnyView(EmptyView())
        }
        
        guard case .int(let componentCount) = componentCountData.value else {
            return AnyView(EmptyView())
        }
        
        guard let componentsData = nodeData.filter({$0.key == JelloNodeDataKey.value.rawValue}).first else {
            return AnyView(EmptyView())
        }
        
        let sliderDisabled: Bool = (nodeData.filter({$0.key == JelloNodeDataKey.componentSliderDisabled.rawValue}).first?.value ?? .bool(false)) == .bool(true)
        
        guard case .float4(let x, let y, let z, let w) = componentsData.value else {
            return AnyView(EmptyView())
        }

        var outputComponents = [x, y, z, w]
        
        let selectorList = getSelectorList()
        
        return AnyView(ZStack {
            VStack {
                Text(node.name ?? "Unknown").font(.title2).minimumScaleFactor(0.2)
                    .bold()
                    .monospaced()
                    .foregroundStyle(.white)
                Spacer()
                DiscreteSliderView(labels: ["v1", "v2", "v3", "v4"], fillPriors: true, fill: Gradient(colors: [.blue, .orange]), disabled: false, item: .init(get: {componentCount - 1}, set: {
                    value in
                    componentCountData.value = .int(value + 1)
                    let sliderHeight: Float = Float(80 * (Float(Float(value) + Float(1.0))))
                    let nodeHeight: Float = Float(JelloNode.headerHeight) + sliderHeight + Float(JelloNode.padding * 2)
                    node.size = .init(width: node.size.width, height: CGFloat(nodeHeight))
                    let outputPort = outputPorts.first!
                    switch(value + 1) {
                    case 1:
                        outputPort.currentDataType = .float
                    case 2:
                        outputPort.currentDataType = .float2
                    case 3:
                        outputPort.currentDataType = .float3
                    case 4:
                        outputPort.currentDataType = .float4
                    default:
                        fatalError("Unsupported component count")
                    }
                })).frame(width: 200, height: 30).padding(5)
                ForEach(0..<componentCount, id: \.self) { i in
                    Spacer(minLength: 20)
                    DiscreteSliderView(labels: selectorList, fillPriors: false, fill: Gradient(colors: [.blue, .orange]), disabled: false, item: .init(get: { Int(outputComponents[i]) }, set: { value in
                        outputComponents[i] = Float(value)
                        componentsData.value = .float4(outputComponents[0], outputComponents[1], outputComponents[2], outputComponents[3])
                    })).frame(width: 200, height: 30).padding(5)
                }
                Spacer(minLength: JelloNode.padding)
            }
            .padding(.all, JelloNode.padding)
        })
    }
}
