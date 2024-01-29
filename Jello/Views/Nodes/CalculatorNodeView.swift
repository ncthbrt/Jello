//
//  CalculatorNodeView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/27.
//

import SwiftUI
import SwiftData

struct CalculatorNodeView : View {
    private var node: JelloNode
    private var drawBounds: (inout Path) -> ()
    @Query private var nodeData: [JelloNodeData]
    @State private var isValid = false
    
    init(node: JelloNode, drawBounds:  @escaping (inout Path) -> ()) {
        self.node = node
        self.drawBounds = drawBounds
        let nodeId = node.uuid
        self._nodeData = Query(filter: #Predicate<JelloNodeData> { data in data.node?.uuid == nodeId })
    }
    
    var body: some View {
        guard let expressionData = nodeData.filter({$0.key == JelloNodeDataKey.value.rawValue}).first else {
            return AnyView(EmptyView())
        }
        guard case .stringArray(let expression) = expressionData.value else {
            return AnyView(EmptyView())
        }
        
        let expressionBinding: Binding<[String]> = .init(get: { expression.value }, set: { value in
            expressionData.value = .stringArray(StringArray(value: value))
            let result = try? parseMathExpression(value.joined(separator: ""))
            isValid = result != nil
        })
        
        
        return AnyView(ZStack {
            VStack {
                Text(node.name ?? "Unknown").font(.title2).minimumScaleFactor(0.2)
                    .bold()
                    .monospaced()
                    .foregroundStyle(.white)
                Spacer()
                VStack {
                    CalculatorView(value: expressionBinding, valid: isValid)
                        .frame(width: 300, height: 360)
                }
            }
            .padding(.all, JelloNode.padding)
        })
    }
}
