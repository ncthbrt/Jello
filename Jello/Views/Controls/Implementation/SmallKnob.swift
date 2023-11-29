import SwiftUI

/// Knob in which you start by tapping in its bound and change the value by either horizontal or vertical motion
public struct SmallKnob<Foreground : ShapeStyle, Background: ShapeStyle>: View {
    @Binding var value: Float
    var range: ClosedRange<Float> = 0.0 ... 1.0

    var background: Background
    var foreground: Foreground

    /// Initialize the knob with a bound value and range
    /// - Parameters:
    ///   - value: value being controlled
    ///   - range: range of the value
    public init(value: Binding<Float>, range: ClosedRange<Float> = 0.0 ... 1.0, foreground: Foreground, background: Background) {
        _value = value
        self.range = range
        self.foreground = foreground
        self.background = background
    }

    var normalizedValue: Double {
        Double((value - range.lowerBound) / (range.upperBound - range.lowerBound))
    }

    public var body: some View {
        Control(value: $value, in: range,
                geometry: .twoDimensionalDrag(xSensitivity: 1, ySensitivity: 1)) { geo in
            ZStack(alignment: .center) {
                Ellipse().foregroundStyle(background.shadow(.inner(color: .black,radius: 10)))
                UnevenRoundedRectangle(cornerRadii: RectangleCornerRadii(topLeading: 1000, topTrailing: 1000)).foregroundStyle(foreground.shadow(.inner(color: .black.opacity(0.5), radius: 2)))
                    .frame(width: geo.size.width / 20, height: geo.size.height / 4)
                    .rotationEffect(Angle(radians: normalizedValue * 1.6 * .pi + 0.2 * .pi))
                    .offset(x: -sin(normalizedValue * 1.6 * .pi + 0.2 * .pi) * geo.size.width / 2.0 * 0.75,
                            y: cos(normalizedValue * 1.6 * .pi + 0.2 * .pi) * geo.size.height / 2.0 * 0.75)
            }.drawingGroup() // Drawing groups improve antialiasing of rotated indicator
        }
        .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)

    }
}




#Preview {
    HStack {
        SmallKnob(value: .constant(4), range: Float(0.0)...Float(20.0), foreground: .thickMaterial, background: .gray).squareFrame(200)
    }.padding(100).background(.black, in: .rect)
}
