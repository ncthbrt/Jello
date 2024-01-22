//
//  ColorNodeView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/01.
//

import Foundation
import SwiftUI
import SwiftData

struct ColorNodeView : View {
    private var node: JelloNode
    private var drawBounds: (inout Path) -> ()
    @Query private var nodeData: [JelloNodeData]
    
    init(node: JelloNode, drawBounds:  @escaping (inout Path) -> ()) {
        self.node = node
        self.drawBounds = drawBounds
        let nodeId = node.uuid
        self._nodeData = Query(filter: #Predicate<JelloNodeData> { data in data.node?.uuid == nodeId })
    }
    
    var body: some View {
        guard let colorData = nodeData.filter({$0.key == JelloNodeDataKey.value.rawValue}).first else {
            return AnyView(EmptyView())
        }
        guard case .float4(let h, let s, let b, let a) = colorData.value else {
            return AnyView(EmptyView())
        }
        
        
        guard let positionData = nodeData.filter({$0.key == JelloNodeDataKey.position.rawValue}).first else {
            return AnyView(EmptyView())
        }
        guard case .float2(let x, let y) = positionData.value else {
            return AnyView(EmptyView())
        }
        
        
        let hueBinding: Binding<Double> = .init(get: { Double(h) }, set: { value in
            colorData.value = .float4(Float(value), Float(s), Float(b), Float(a))
        })
        
        let alphaBinding: Binding<Double> = .init(get: { Double(a) }, set: { value in
            colorData.value = .float4(Float(h), Float(s), Float(b), Float(value))
        })
        let saturationBrightnessPositionBinding: Binding<(x: Double, y: Double)> = .init(get: { (x: Double(x), y: Double(y)) }, set: { value in
            let saturationBrightness = ColorSaturationBrightnessCircle.convertToSaturationBrightness(x: value.x, y: value.y)
            positionData.value = .float2(Float(value.x), Float(value.y))
            colorData.value = .float4(h, Float(saturationBrightness.b), Float(saturationBrightness.s), a)
        })
        
        return AnyView(ZStack {
            VStack {
                Text(node.name ?? "Unknown").font(.title2).minimumScaleFactor(0.2)
                    .bold()
                    .monospaced()
                    .foregroundStyle(.white)
                Spacer()
                VStack {
                    ZStack {
                        GeometryReader { geometry in
                            ColorWheel(hue: hueBinding, frame: geometry.frame(in: .local), strokeWidth: 25)
                            ColorSaturationBrightnessCircle(hue: Double(h), position: saturationBrightnessPositionBinding, frame: geometry.frame(in: .local), strokeWidth: 25)
                        }.frame(width: 250, height: 250)
                    }
                    Spacer(minLength: 10)
                    OpacitySlider(color: (h: Double(h), s: Double(s), b: Double(b)), alpha: alphaBinding).frame(width: 250, height: 50).offset(.zero)
                }
            }
            .padding(.all, JelloNode.padding)
        })
    }
}
