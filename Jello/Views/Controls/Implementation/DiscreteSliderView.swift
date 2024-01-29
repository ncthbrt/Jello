//
//  DiscreteSliderView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/19.
//

import Foundation

import SwiftUI

fileprivate struct GooballShapeSlider : Shape {
    var position: CGFloat
    let circleRadius: CGFloat
    let passageRadius: CGFloat
    var width: CGFloat
    var fracTotal: CGFloat
    let i: Int
    let ticks : Int
    let fillPriors: Bool
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        var frac = mapChannelFrac(i: i - 1, frac: fracTotal, ticks: ticks, fillPriors: fillPriors)
        var offset: CGFloat = 0
        if (!fillPriors && frac > 0.45) {
            offset = frac - 0.45
            offset *= 1 / 0.45
            offset *= offset
        }
        frac = frac >= 0.999 ? 0 : frac
        frac = frac < 0 ? 1 : frac
        offset *= circleRadius
        p.addRoundedRect(in: CGRect(x: position - 5 + offset,  y: circleRadius / 2 - passageRadius / 2, width: max(0, ((width + 10) - offset) *  frac), height: passageRadius), cornerSize: CGSize(width: 5, height: 5))
        return p
    }
    
    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, CGFloat> {
        get { .init(.init(fracTotal, position), width) }
        set {
            fracTotal = newValue.first.first
            position = newValue.first.second
            width = newValue.second
        }
    }
    
}

fileprivate struct GooballShape : Shape {
    let circleRadius: CGFloat
    var fracTotal: CGFloat
    let i: Int
    let ticks : Int
    var position: CGFloat
    let fillPriors: Bool
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let frac = mapFrac(i: i, frac: fracTotal, ticks: ticks, fillPriors: fillPriors)
        p.addArc(center: CGPoint(x: position + circleRadius / 2, y: circleRadius / 2),  radius: circleRadius / 2, startAngle: .degrees(90 + 180 * (1 - frac)), endAngle: .degrees(90 - 180 * (1 - frac)), clockwise: true)
        p.closeSubpath()
        return p
    }
    
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { .init(fracTotal, position) }
        set {
            fracTotal = newValue.first
            position = newValue.second
        }
    }
}

func mapFrac(i: Int, frac: CGFloat, ticks: Int, fillPriors: Bool) -> CGFloat {
    let result = frac * CGFloat(ticks - 1)
    if (fillPriors && result >= CGFloat(i))  {
        return 0
    }
    if result >= CGFloat(i) && result <= CGFloat(i + 1) {
        return  (result - CGFloat(i))
    }
    else if result >= CGFloat(i - 1) && result < CGFloat(i) {
        let delta = ( result - CGFloat(i - 1) )
         return 1 - delta * delta * delta
    }
    return 1
}

fileprivate func mapChannelFrac(i: Int, frac: CGFloat, ticks: Int, fillPriors: Bool) -> CGFloat {
    let result = (frac * CGFloat(ticks - 1))
    if (fillPriors && result >= CGFloat(i + 1))  {
        return -1
    }
    if result >= CGFloat(i) && result <= CGFloat(i + 1) {
        return  (result - CGFloat(i))
    }
    return 1
}

fileprivate func clamp0N(value: Int, _ n: Int) -> Int {
    return value > n ? n : (value < 0 ? 0 : value)
}

struct DiscreteSliderView: View {
    let labels: [String]
    let fillPriors: Bool
    let fill: Gradient
    let disabled: Bool
    @State var position: CGFloat = 0
    @State var offset: CGFloat = 0
    
    @Binding var item: Int
    
    init(labels: [String], fillPriors: Bool, fill: Gradient, disabled: Bool, item: Binding<Int>) {
        self.labels = labels
        self.fillPriors = fillPriors
        self.fill = fill
        self.disabled = disabled
        self._item = item
    }
    
    var body: some View {
        GeometryReader { geometry in
            let radius: CGFloat = min(geometry.size.height / 1.5, geometry.size.width / CGFloat(labels.count * 2 - 1))
            let channelWidth =  (geometry.size.width - radius * CGFloat(labels.count)) / (CGFloat(labels.count - 1))
            let width = geometry.size.width
            let rectHeight = radius * 0.45
            let distancePerItem = (radius + channelWidth)
            ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
                HStack(alignment: .top, spacing: 0){
                    VStack(alignment: .center, spacing: 5) {
                        Circle().frame(height: radius).foregroundStyle(.ultraThinMaterial)
                        Text(labels[0]).italic().monospaced().frame(width: radius + 5, height: radius * 0.5)
                    }.frame(width: radius, height: 1.5 * radius).offset(y: 2.5)
                    ForEach(labels.dropFirst(), id: \.self){ label in
                        VStack(alignment: .center, spacing: 5) {
                            HStack(spacing: -5) {
                                Rectangle().frame(width: channelWidth + 10, height: rectHeight)
                                Circle().frame(width: radius)
                            }.frame(height: radius).foregroundStyle(.ultraThinMaterial)
                            Text(label).italic().monospaced().offset(x: (channelWidth) / 2).frame(height: radius / 2)
                        }.frame(width: radius + channelWidth, height: 1.5 * radius).offset(x: -2.5, y: 2.5)
                    }
                }.padding(.zero).frame(height: radius * 1.5)

                let fracTotal = min(1, position / (width - radius))
                GooballShape(circleRadius: radius, fracTotal: fracTotal, i: 0, ticks: labels.count, position: 0, fillPriors: fillPriors).fill(fill).frame(height: radius)
                ForEach(1..<labels.count, id: \.self){
                    i in
                    GooballShapeSlider(position: CGFloat(i - 1) * distancePerItem + radius, circleRadius: radius, passageRadius: rectHeight, width: channelWidth, fracTotal: fracTotal, i: i, ticks: labels.count, fillPriors: fillPriors).fill(fill).frame(height: radius)
                    GooballShape(circleRadius: radius, fracTotal: fracTotal, i: i, ticks: labels.count, position: CGFloat(i) * distancePerItem, fillPriors: fillPriors).fill(fill).frame(height: radius)
                }
            }.frame(width: width, height: radius * 2.5).gesture(DragGesture().onChanged({
                event in
                if !disabled {
                    withAnimation(.interactiveSpring){
                        position += (event.translation.width - offset)
                        position = min(max(0, CGFloat(position)), width - radius)
                        offset = event.translation.width
                        let distancePerItem = (width - radius) /  CGFloat(labels.count - 1)
                        item = clamp0N(value: Int(round(position / distancePerItem)), labels.count - 1)
                    }
                }
            }).onEnded({ event in
                if !disabled {
                    withAnimation(.spring) {
                        offset = 0
                        item = clamp0N(value: Int(round(position / distancePerItem)), labels.count - 1)
                        position = CGFloat(CGFloat(item) * distancePerItem)
                    }
                }
            })).gesture(SpatialTapGesture().onEnded({ event in
                if !disabled {
                    withAnimation(.interactiveSpring(response: 0.9, dampingFraction: 0.55, blendDuration: 0.15)){
                        position = event.location.x
                        item = clamp0N(value: Int(round(position / distancePerItem)), labels.count - 1)
                        position = CGFloat(CGFloat(item) * distancePerItem)
                    }
                }
            })).onChange(of: item, { _, current in
                withAnimation(.interactiveSpring(response: 0.9, dampingFraction: 0.55, blendDuration: 0.15)){
                    position = CGFloat(CGFloat(item) * distancePerItem)
                }
            }).onChange(of: labels.count, { _ , current in
                if (item >= labels.count){
                    item = labels.count - 1
                }
                position = CGFloat(CGFloat(item) * distancePerItem)
            }).opacity(disabled ? 0.4 : 1)
        }
    }
}

