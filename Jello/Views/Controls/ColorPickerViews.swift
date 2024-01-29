//
//  ColorPickerViews.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/20.
//

import Foundation
import SwiftUI


struct OpacitySlider: View {
    let color: (h: Double, s: Double, b: Double)
    @Binding var alpha: Double
    @State private var isDragging: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let indicatorHeight = isDragging ? geometry.size.height : geometry.size.height * 0.75
            let indicatorWidth: CGFloat = isDragging ? 30 : 15
            let indicatorOffset: CGFloat = (geometry.size.height - indicatorHeight) / 2
            let position: CGPoint = CGPoint.lerp(a: .init(x: 0, y: indicatorOffset), b: .init(x: geometry.size.width - indicatorWidth, y: indicatorOffset), t: Float(alpha))
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: geometry.size.height / 4.0)
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.7)
                    .colorEffect(ShaderLibrary.checkerboard(.color(Color(hue: color.h, saturation: color.s, brightness: color.b)), .float(12), .float(geometry.size.width))).shadow(radius: 4)
                    .allowsHitTesting(true)
                    .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local).onChanged({
                        event in update(geometry: geometry, event: event)
                    }).onEnded({ event in
                        update(geometry: geometry, event: event)
                        withAnimation(.easeOut) {
                            isDragging = false
                        }
                    }))
                RoundedRectangle(cornerRadius: geometry.size.height / 8).size(width: indicatorWidth, height: indicatorHeight).fill(Color(hue: color.h, saturation: color.s, brightness: color.b, opacity: CGFloat(alpha))).stroke(.white, lineWidth: 5)
                    .allowsHitTesting(false).shadow(radius: 5).offset(x: position.x, y: position.y)
            }.frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    func update(geometry: GeometryProxy, event: DragGesture.Value) {
        let indicatorWidth: CGFloat = isDragging ? 30 : 15
        let a = (event.location.x / (geometry.size.width - indicatorWidth))
        alpha = Double(max(min(1, a), 0))
        if !isDragging {
            withAnimation(.interactiveSpring) {
                isDragging = true
            }
        }
    }
    
}

extension Angle {
    var color: UIColor {
        UIColor(hue: CGFloat(self.radians / (2 * .pi)), saturation: 1, brightness: 1, alpha: 1)
    }
    
    func color(saturation: CGFloat, brightness: CGFloat) -> UIColor {
        UIColor(hue: CGFloat(self.radians / (2 * .pi)), saturation: saturation, brightness: brightness, alpha: 1)
    }
    
    func colorView(saturation: CGFloat, brightness: CGFloat) -> Color {
        Color(hue: CGFloat(self.radians / (2 * .pi)), saturation: saturation, brightness: brightness)
    }
    
    var colorView: Color {
        Color(hue: self.radians / (2 * .pi), saturation: 1, brightness: 1)
    }
}

extension UIColor {
    var angle: Angle {
        Angle(radians: Double(2 * .pi * self.hueComponent))
    }
    

    /**
     Returns the HSB (hue, saturation, brightness) components.

     - returns: The HSB components as a tuple (h, s, b).
     */
    public final func toHSBComponents() -> (h: CGFloat, s: CGFloat, b: CGFloat) {
        var h: CGFloat = 0.0
        var s: CGFloat = 0.0
        var b: CGFloat = 0.0

        getHue(&h, saturation: &s, brightness: &b, alpha: nil)

        return (h: h, s: s, b: b)
    }
      /**
       The hue component as CGFloat between 0.0 to 1.0.
       */
      public final var hueComponent: CGFloat {
        return toHSBComponents().h
      }

      /**
       The saturation component as CGFloat between 0.0 to 1.0.
       */
      public final var saturationComponent: CGFloat {
        return toHSBComponents().s
      }

      /**
       The brightness component as CGFloat between 0.0 to 1.0.
       */
      public final var brightnessComponent: CGFloat {
        return toHSBComponents().b
      }
}

extension Gradient {
    static let colorWheelSpectrum: Gradient = Gradient(colors: [
        Angle(radians: 3/6 * .pi).colorView,
        
        Angle(radians: 2/6 * .pi).colorView,
        Angle(radians: 1/6 * .pi).colorView,
        Angle(radians: 12/6 * .pi).colorView,
        
        Angle(radians: 11/6 * .pi).colorView,
        
        Angle(radians: 10/6 * .pi).colorView,
        Angle(radians: 9/6 * .pi).colorView,
        Angle(radians: 8/6 * .pi).colorView,
        
        Angle(radians: 7/6 * .pi).colorView,
        
        Angle(radians: 6/6 * .pi).colorView,
        Angle(radians: 5/6 * .pi).colorView,
        Angle(radians: 4/6 * .pi).colorView,
        
        Angle(radians: 3/6 * .pi).colorView,
    ])
}


extension AngularGradient {
    static let conic = AngularGradient(gradient: Gradient.colorWheelSpectrum, center: .center, angle: .degrees(-90))
}

func saturate(x: CGFloat) -> CGFloat {
    return x > 1 ? 1: (x < 0 ? 0 : x)
}


func remap(x: CGFloat, startOld: CGFloat, endOld: CGFloat, startNew: CGFloat, endNew: CGFloat) -> CGFloat {
    let frac = (x - startOld) / (endOld - startOld)
    return startNew + (frac * (endNew - startNew))
}

public struct ColorWheel: View {
    @Binding var hue : Double
    public var frame: CGRect
    public var strokeWidth: CGFloat
    @State private var isDragging: Bool = false
    
    public var body: some View {
        let indicatorSize = (isDragging ? 1.6 : 1.2) * strokeWidth
        let indicatorOffset = CGSize(
            width: cos(hue * 2 * .pi) * Double(frame.midX - (strokeWidth) / 2),
            height: -sin(hue * 2 * .pi) * Double(frame.midY - (strokeWidth) / 2))
        return ZStack(alignment: .center) {
            // Color Gradient
            Circle()
                .strokeBorder(AngularGradient.conic, lineWidth: strokeWidth)
                .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged(self.update(value:))
                    .onEnded({ event in 
                        withAnimation(.easeOut) {
                            isDragging = false
                        }})
                )
            // Color Selection Indicator
            Circle()
                .fill(Color(hue: hue, saturation: 1, brightness: 1))
                .frame(width: indicatorSize, height: indicatorSize, alignment: .center)
                .fixedSize()
                .offset(indicatorOffset)
                .allowsHitTesting(false)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 5)
                        .offset(indicatorOffset)
                        .allowsHitTesting(false)
                )
        }
    }
    
    public init(hue: Binding<Double>, frame: CGRect, strokeWidth: CGFloat) {
        self.frame = frame
        self._hue = hue
        self.strokeWidth = strokeWidth
    }
    
    func update(value: DragGesture.Value) {
        self.hue = radCenterPoint(value.location, frame: frame) / (.pi * 2)
        if (!isDragging) {
            withAnimation(.interactiveSpring) {
                isDragging  = true
            }
        }
    }
    
    func radCenterPoint(_ point: CGPoint, frame: CGRect) -> Double {
        let adjustedAngle = atan2f(Float(frame.midX - point.x), Float(frame.midY - point.y)) + .pi / 2
        return Double(adjustedAngle < 0 ? adjustedAngle + .pi * 2 : adjustedAngle)
    }
}



public struct ColorSaturationBrightnessCircle: View {
    let hue: Double
    @Binding var position: (x: Double, y: Double)
    public var frame: CGRect
    public var strokeWidth: CGFloat
    @State private var isDragging: Bool = false
    @State var startDate = Date()
    
    public var body: some View {
        return ZStack {
            GeometryReader { geometry in
                let indicatorSize = (isDragging ? 1.75 : 1.4) * strokeWidth
                let circleDiameter = geometry.size.width
                
                let saturationBrightness = ColorSaturationBrightnessCircle.convertToSaturationBrightness(x: position.x, y: position.y)
                let indicatorOffset = CGSize(
                    width: remap(x: position.x, startOld: -1, endOld: 1, startNew: 0, endNew: circleDiameter) - indicatorSize / 2,
                    height: remap(x: position.y, startOld: -1, endOld: 1, startNew: 0, endNew: circleDiameter) - indicatorSize / 2
                )
                
                // Color Gradient
                    Circle()
                        .fill(.white)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .colorEffect(ShaderLibrary.hsbEffect(.float(hue), .float(geometry.size.width)))
                        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local).onChanged({
                            event in update(value: event.location, geometry: geometry)
                        }).onEnded({ event in
                            update(value: event.location, geometry: geometry)
                            withAnimation(.easeOut) {
                                isDragging = false
                            }
                        }))
                Circle()
                    .fill(Color(hue: hue, saturation: saturationBrightness.s, brightness: saturationBrightness.b))
                    .frame(width: indicatorSize, height: indicatorSize, alignment: .center)
                    .offset(indicatorOffset)
                    .allowsHitTesting(false)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 5)
                            .shadow(radius: 10)
                            .offset(indicatorOffset)
                            .allowsHitTesting(false)
                    )
            }.padding(strokeWidth * 2)
        }
    }
    
    static func convertToSaturationBrightness(x: Double, y: Double) -> (s: Double, b: Double) {
        let pos = CGPoint(x: x, y: y)
        let u = pos.x * sqrt(1 - (pos.y * pos.y) / 2);
        let v = pos.y * sqrt(1 - (pos.x * pos.x) / 2);
        let saturationLightness = CGPoint(
            x: remap(x: u, startOld: -1, endOld: 1, startNew: 0, endNew: 1),
            y: remap(x: v, startOld: -1, endOld: 1, startNew: 1, endNew: 0)
        )
        return (s: Double(saturationLightness.x), b: Double(saturationLightness.y))
    }


    func update(value: CGPoint, geometry: GeometryProxy) {
        let positionIntermediate = (x: Double(remap(x: min(geometry.size.width,  value.x), startOld: 0, endOld: geometry.size.width, startNew: -1, endNew: 1)), y: Double(remap(x: min(geometry.size.width, value.y), startOld: 0, endOld: geometry.size.width, startNew: -1, endNew: 1)))
        let radius = sqrt(positionIntermediate.x * positionIntermediate.x + positionIntermediate.y * positionIntermediate.y)
        let clampedRadius = min(1, radius)
        position = (x: (positionIntermediate.x / radius) * clampedRadius, y: (positionIntermediate.y / radius) * clampedRadius)
        if !isDragging {
            withAnimation(.interactiveSpring) {
                isDragging = true
            }
        }

    }

}


#Preview {
    ZStack(alignment: .center) {
        Rectangle().foregroundStyle(.ultraThinMaterial)
        VStack {
            ZStack {
                GeometryReader { geometry in
                    ColorWheel(hue: .constant(0.1), frame: geometry.frame(in: .local), strokeWidth: 25)
                    ColorSaturationBrightnessCircle(hue: 0, position: .constant((x: 1, y: 1)), frame: geometry.frame(in: .local), strokeWidth: 25)
                }.frame(width: 250, height: 250)
            }
            OpacitySlider(color: (0, 1, 1), alpha: .constant(0.5)).frame(width: 250, height: 50).offset(.zero)
        }
    }
}
