//
//  ComputeNodeView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/02/06.
//

import Foundation
import SwiftUI
import SwiftData



struct ComputeNodeView : View {
    private var node: JelloNode
    private var drawBounds: (inout Path) -> ()
    @Query private var nodeData: [JelloNodeData]
    
    init(node: JelloNode, drawBounds:  @escaping (inout Path) -> ()) {
        self.node = node
        self.drawBounds = drawBounds
        let nodeId = node.uuid
        self._nodeData = Query(filter: #Predicate<JelloNodeData> { data in data.node?.uuid == nodeId })
    }
    
    private let resolutionList: [Int] = [8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096]
    
    
    var body: some View {
        guard let dimensionData = nodeData.filter({$0.key == JelloNodeDataKey.value.rawValue}).first else {
            return AnyView(EmptyView())
        }
        guard case .int3(let x, let y, let z) = dimensionData.value else {
            return AnyView(EmptyView())
        }
        
        let typeSliderDisabled: Bool = nodeData.filter({$0.key == JelloNodeDataKey.typeSliderDisabled.rawValue}).first?.value == .some(.bool(true))

        
        return AnyView(ZStack {
            VStack {
                Text(node.name ?? "Unknown").font(.title2).minimumScaleFactor(0.2)
                    .bold()
                    .monospaced()
                    .foregroundStyle(.white)
                Spacer()
                DiscreteSliderView(labels: ["1d", "2d", "3d"], fillPriors: true, fill: Gradient(colors: [.blue, .orange]), disabled: typeSliderDisabled, item: .init(get: { (z > 1) ? 2 : (y > 1 ? 1 : 0) }, set: {
                    value in
                    if value == 0 {
                        dimensionData.value = .int3(x, 1, 1)
                    }
                    else if value == 1 {
                        dimensionData.value = .int3(x, y == 1 ? resolutionList[0] : y, 1)
                    } else {
                        dimensionData.value = .int3(x, y, z == 1 ? resolutionList[0] : z)
                    }
                    let sliderHeight: Float = Float(80 * (Float(Float(value) + Float(1.0))))
                    let nodeHeight: Float = Float(JelloNode.headerHeight) + sliderHeight + Float(JelloNode.padding * 2)
                    node.size = .init(width: node.size.width, height: CGFloat(nodeHeight))
                })).frame(width: 200, height: 30).padding(5)
                Spacer(minLength: 20)
                Picker(selection: .init(get: { resolutionList.firstIndex(of: x) ?? 0 }, set: {
                    value in
                    dimensionData.value = .int3(resolutionList[value], y, z)
                }), content: {
                    ForEach(resolutionList.indices, id: \.self) { i in
                        Text("\(resolutionList[i])").tag(i)
                    }
                }, label: {
                    Text("X")
                }).pickerStyle(.menu)
                if y > 1 {
                    Spacer(minLength: 20)
                    Picker(selection: .init(get: { resolutionList.firstIndex(of: y) ?? 0 }, set: {
                        value in
                        dimensionData.value = .int3(x, resolutionList[value], z)
                    }), content: {
                        ForEach(resolutionList.indices, id: \.self) { i in
                            Text("\(resolutionList[i])").tag(i)
                        }
                    }, label: {
                        Text("Y")
                    }).pickerStyle(.menu)
                }
                if z > 1 {
                    Spacer(minLength: 20)
                    Picker(selection: .init(get: { resolutionList.firstIndex(of: z) ?? 0 }, set: {
                        value in
                        dimensionData.value = .int3(x, y, resolutionList[value])
                    }), content: {
                        ForEach(resolutionList.indices, id: \.self) { i in
                            Text("\(resolutionList[i])").tag(i)
                        }
                    }, label: {
                        Text("Z")
                    }).pickerStyle(.menu)
                }
            }
            .padding(.all, JelloNode.padding)
        })
    }
}
