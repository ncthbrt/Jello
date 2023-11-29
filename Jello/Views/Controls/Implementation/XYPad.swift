import SwiftUI

/// XY control that doesn't snap
public struct XYPad: View {
    @Binding var x: Float
    @Binding var y: Float

    var backgroundColor: Color = .gray
    var foregroundColor: Color = .red
    var cornerRadius: CGFloat = 0
    var indicatorPadding: CGFloat = 0.2
    var indicatorSize: CGSize = CGSize(width: 40, height: 40)

    /// Initiate the control with two parameters
    /// - Parameters:
    ///   - x: horizontal parameter 0-1
    ///   - y: vertical parameter 0-1
    public init(x: Binding<Float>, y: Binding<Float>) {
        _x = x
        _y = y
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius).foregroundColor(backgroundColor)
            TwoParameterControl(value1: $x, value2: $y,
                                geometry: .rectilinear,
                                padding: CGSize(width: indicatorSize.width / 2,
                                                height: indicatorSize.height / 2)
            ) { geo in
                Canvas { cx, size in
                    let viewport = CGRect(origin: .zero, size: size)
                    let indicatorRect = CGRect(origin: .zero, size: indicatorSize)

                    let activeWidth = viewport.size.width - indicatorRect.size.width
                    let activeHeight = viewport.size.height - indicatorRect.size.height

                    let offsetRect = indicatorRect
                        .offset(by: CGSize(width: activeWidth * CGFloat(x),
                                           height: activeHeight * (1 - CGFloat(y))))
                    let cr = min(indicatorRect.height / 2, cornerRadius)
                    let ind = Path(roundedRect: offsetRect, cornerRadius: cr)

                    cx.fill(ind, with: .color(foregroundColor))
                }
            }.padding(indicatorSize.height * indicatorPadding)
        }
    }
}

extension XYPad {
    /// Modifier to change the background color of the xy pad
    /// - Parameter backgroundColor: background color
    public func backgroundColor(_ backgroundColor: Color) -> XYPad {
        var copy = self
        copy.backgroundColor = backgroundColor
        return copy
    }

    /// Modifier to change the foreground color of the xy pad
    /// - Parameter foregroundColor: foreground color
    public func foregroundColor(_ foregroundColor: Color) -> XYPad {
        var copy = self
        copy.foregroundColor = foregroundColor
        return copy
    }

    /// Modifier to change the corner radius of the xy pad and the indicator
    /// - Parameter cornerRadius: radius (make very high for a circular indicator)
    public func cornerRadius(_ cornerRadius: CGFloat) -> XYPad {
        var copy = self
        copy.cornerRadius = cornerRadius
        return copy
    }

    /// Modifier to change the size of the indicator
    /// - Parameter indicatorSize: size of the indicator
    public func indicatorSize(_ indicatorSize: CGSize) -> XYPad {
        var copy = self
        copy.indicatorSize = indicatorSize
        return copy
    }
}


#Preview {
    GeometryReader { proxy in
          VStack(alignment: .leading, spacing: 20) {
              Text("Controls two parameters in the x- and y-dimensions")
              Slider(value: .constant(0.5))
              Slider(value: .constant(0.5))
              Text("Customizable colors and corner radius")
              VStack(alignment: .center, spacing: 40) {
                  HStack(spacing: 40) {
                      XYPad(x: .constant(0.5), y: .constant(0.5))
                          .backgroundColor(.yellow)
                          .foregroundColor(.blue)
                          .cornerRadius(10)
                          .squareFrame(proxy.size.width / 4)
                      XYPad(x: .constant(0), y: .constant(1))
                          .backgroundColor(.orange)
                          .foregroundColor(.red)
                          .cornerRadius(10)
                          .squareFrame(proxy.size.height / 5)
                  }
                  HStack(spacing: 40) {
                      XYPad(x: .constant(0.85), y: .constant(0.4))
                          .foregroundColor(.white.opacity(0.5))
                          .cornerRadius(10)
                          .indicatorSize(CGSize(width: 60, height: 60))
                          .squareFrame(proxy.size.height / 3)
                      VStack{
                          XYPad(x: .constant(0.85), y: .constant(0.4))
                              .backgroundColor(.primary)
                              .foregroundColor(.accentColor)
                              .indicatorSize(CGSize(width: 120, height: 50))
                              .cornerRadius(20)
                              .squareFrame(proxy.size.height / 3)

                      }

                  }
              }
          }
      }
      .navigationTitle("XYPad")
      .padding()
}
