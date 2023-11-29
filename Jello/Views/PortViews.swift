import SwiftUI
import SwiftData

struct InputPortView : View {
    let port: JelloInputPort
    @Environment(\.freeEdges) var freeEdges: [(edge: JelloEdge, dependencies: Set<UUID>)]
    
    var body: some View {
        let highlightPort = port.edge == nil && freeEdges.contains(where: { JelloGraphDataType.isPortTypeCompatible(edge: $0.edge.dataType, port: port.dataType) && !$0.dependencies.contains(port.node?.uuid ?? UUID()) })

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
        }
        .frame(height: JelloNode.portHeight, alignment: .topLeading)
        .position(port.nodeOffset + CGPoint(x: JelloNode.outputPortDiameter/2, y: JelloNode.outputPortDiameter / 4))
    }
}

struct OutputPortView : View {
    let port: JelloOutputPort
    @State var dragStarted: Bool = false
    @State private var newEdge : JelloEdge? = nil
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
            HStack {
                Text(port.name)
                    .font(.body.monospaced())
                    .italic()
                Circle()
                    .fill(port.dataType.getTypeGradient())
                    .frame(width: JelloNode.outputPortDiameter, height: JelloNode.outputPortDiameter, alignment: .center)
            }
            .frame(height: JelloNode.portHeight, alignment: .topTrailing)
            .position(port.nodeOffset + CGPoint(x: -JelloNode.outputPortDiameter/2, y: JelloNode.outputPortDiameter / 4))
            .sensoryFeedback(trigger: dragStarted) { oldValue, newValue in
                return newValue ? .start : .stop
            }
            .gesture(DragGesture().onChanged({ drag in
                if newEdge == nil, let graph = port.node?.graph {
                    dragStarted = true
                    let nEdge = JelloEdge(graph: graph, uuid: UUID(), dataType: port.dataType, outputPort: port, inputPort: nil, startPositionX: port.positionX, startPositionY: port.positionY, endPositionX: port.positionX, endPositionY: port.positionY)
                    newEdge = nEdge
                    modelContext.insert(nEdge)
                }
                newEdge!.endPosition = (newEdge!.startPosition + CGPoint(x: drag.translation.width, y: drag.translation.height))
            }).onEnded({ drag in
                newEdge?.endPosition = (newEdge!.startPosition + CGPoint(x: drag.translation.width, y: drag.translation.height))
                if let nEdge = newEdge, nEdge.inputPort == nil {
                    modelContext.delete(nEdge)
                }
                newEdge = nil
                dragStarted = false
            }))
    }
}


struct NodeOutputPortsView: View {
    @Query var outputPorts: [JelloOutputPort]

    init(nodeId: UUID) {
        self._outputPorts = Query(FetchDescriptor(predicate: #Predicate { $0.node?.uuid == nodeId }, sortBy: [SortDescriptor(\.index)]), animation: .bouncy)
    }
    
    var body: some View  {
        ForEach(outputPorts) {
            output in OutputPortView(port: output)
        }.frame(alignment: .topLeading)
    }
}

struct NodeInputPortsView: View {
    @Query var inputPorts: [JelloInputPort]

    init(nodeId: UUID) {
        self._inputPorts = Query(FetchDescriptor(predicate: #Predicate { $0.node?.uuid == nodeId }, sortBy: [SortDescriptor(\.index)]), animation: .bouncy)
    }
    
    var body: some View  {
        ForEach(inputPorts) {
            input in InputPortView(port: input)
        }.frame(alignment: .topLeading)
    }
}
