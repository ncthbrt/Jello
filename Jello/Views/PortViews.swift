import SwiftUI

struct InputPortView : View {
    let port: JelloInputPort
    let highlightPort: Bool
    
    var body: some View {
        HStack {
            ZStack {
                if highlightPort {
                    Circle()
                        .fill(RadialGradient(colors: [.green.opacity(0.8), .clear], center: UnitPoint(x: 0.5, y: 0.5), startRadius: 0, endRadius: JelloNode.inputPortDiameter * 0.3))
                        .frame(width: JelloNode.inputPortDiameter, height: JelloNode.inputPortDiameter, alignment: .leading)
                        .animation(.easeIn, value: highlightPort)
                }
                let portCircle = Circle()
                    .stroke(lineWidth: JelloNode.inputPortStrokeWidth)
                    .fill(port.dataType.getTypeGradient())
                    .frame(width: JelloNode.inputPortDiameter, height: JelloNode.inputPortDiameter, alignment: .leading)
                if highlightPort {
                    portCircle.shadow(color: .green, radius: 4)
                } else {
                    portCircle
                }
            }.animation(.easeIn.speed(2), value: highlightPort)
            Text(port.name)
                .italic()
                .monospaced()
        }.frame(width: JelloNode.nodeWidth / 2, height: JelloNode.portHeight, alignment: .topLeading)
    }
}

struct OutputPortView : View {
    let port: JelloOutputPort
    
    var body: some View {
            HStack {
                Text(port.name)
                    .font(.body.monospaced())
                    .italic()
                Circle()
                    .fill(port.dataType.getTypeGradient())
                    .frame(width: JelloNode.outputPortDiameter, height: JelloNode.outputPortDiameter, alignment: .center)
            }.frame(width: JelloNode.nodeWidth / 2, height: JelloNode.portHeight, alignment: .topTrailing)
    }
}
