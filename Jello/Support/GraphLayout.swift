import SwiftUI
import OrderedCollections
import Collections

enum PortRelativeTo {
    case nodeSpace
    case worldSpace
}

extension JelloNode {
    static let headerHeight: CGFloat = 60.0
    static let portHeight: CGFloat = 30.0
    static let nodeWidth: CGFloat = 175.0
    static let padding: CGFloat = 15.0
    static let cornerRadius: CGFloat = 20.0
    static let outputPortDiameter : CGFloat = 20.0
    static let inputPortDiameter : CGFloat = 17.0
    static let inputPortStrokeWidth : CGFloat = 3.0

    func computeNodeHeight() -> CGFloat {
        return Self.headerHeight + JelloNode.portHeight * CGFloat(max(self.inputPorts.count, self.outputPorts.count))
    }
    
    func getInputPortPositionOffset(portId: UUID, relativeTo: PortRelativeTo) -> CGPoint {
        switch relativeTo {
        case .nodeSpace:
            return CGPoint(x: JelloNode.padding + JelloNode.nodeWidth / 4, y: JelloNode.headerHeight) + CGPoint(x: 0, y: JelloNode.portHeight) * CGFloat(self.inputPorts.firstIndex(where: { portId == $0.id }) ?? 0)
        case .worldSpace:
            return CGPoint(x: JelloNode.padding, y: JelloNode.headerHeight) + CGPoint(x: 0, y: JelloNode.portHeight) * CGFloat(self.inputPorts.firstIndex(where: { portId == $0.id }) ?? 0)
        }
    }
    
    func getOutputPortPositionOffset(portId: UUID, relativeTo: PortRelativeTo) -> CGPoint {
        switch relativeTo {
        case .nodeSpace:
            return CGPoint(x: JelloNode.nodeWidth - JelloNode.padding - JelloNode.nodeWidth / 4, y: JelloNode.headerHeight) + CGPoint(x: 0, y: JelloNode.portHeight) * CGFloat(self.outputPorts.firstIndex(where: { portId == $0.id }) ?? 0)
        case .worldSpace:
            return CGPoint(x: JelloNode.nodeWidth - JelloNode.padding, y: JelloNode.headerHeight) + CGPoint(x: 0, y: JelloNode.portHeight) * CGFloat(self.outputPorts.firstIndex(where: { portId == $0.id }) ?? 0)
        }
    }
    
    func getOutputPortWorldPosition(outputPortId: UUID) -> CGPoint {
        return self.position - CGPoint(x: JelloNode.nodeWidth / 2, y:  self.computeNodeHeight() / 2) + self.getOutputPortPositionOffset(portId: outputPortId, relativeTo: .worldSpace) + CGPoint(x:  -(JelloNode.outputPortDiameter) / 2, y: -ceil(JelloNode.outputPortDiameter / 4))
    }
    
    func getInputPortWorldPosition(inputPortId: UUID) -> CGPoint {
      return self.position - CGPoint(x: JelloNode.nodeWidth / 2, y: self.computeNodeHeight() / 2) + self.getInputPortPositionOffset(portId: inputPortId, relativeTo: .worldSpace) + CGPoint(x: JelloNode.inputPortDiameter / 2, y: -ceil(JelloNode.inputPortDiameter / 4))
    }
}


//extension Edge {
//    static let maxEdgeSnapDistance: CGFloat = 50.0
//    
//    func getStartPosition() -> CGPoint {
//        return self.outputNode.getOutputPortWorldPosition(outputPortId: outputPort.id)
//    }
//    
//    func getEndPosition() -> CGPoint {
//        return self.inputNode!.getInputPortWorldPosition(inputPortId: inputPort!.id)
//    }
//    
//
//    func setEndPosition(_ position: CGPoint, graph: Graph, dependencies: Set<JelloNode.ID>) {
//        var minDist: CGFloat = CGFloat.greatestFiniteMagnitude
//        var minPort: (node: Node, JelloPort: JelloPort)? = nil
//        // TODO: Test if this is performant enough at scale
//        for node in graph.nodes.values {
//            if !dependencies.contains(node.id) {
//                for JelloPort in node.inputPorts {
//                    if GraphDataType.isPortTypeCompatible(edge: dataType, JelloPort: JelloPort.dataType) {
//                        let nodePosition = node.getInputPortWorldPosition(inputPortId: JelloPort.id)
//                        let dist = (position - nodePosition).magnitude()
//                        if dist < minDist && dist <= Edge.maxEdgeSnapDistance {
//                            minDist = dist
//                            minPort = (node: node, JelloPort: JelloPort)
//                        }
//                    }
//                }
//            }
//        }
//        
//        if let JelloPort = minPort {
//            if let iNode = self.inputNode {
//                iNode.removeInputEdge(edge: self)
//            }
//            self.inputNode = JelloPort.node
//            self.inputPort = JelloPort.JelloPort
//            withAnimation(.easeIn.speed(0.5)) {
//                self.dataType = self.outputPort.dataType
//            }
//            self.dataType = GraphDataType.getMostSpecificType(a: self.outputPort.dataType, b: JelloPort.JelloPort.dataType)
//            JelloPort.node.addInputEdge(edge: self)
//        } else {
//            self.endPosition = position
//            if let iNode = self.inputNode {
//                self.inputNode = nil
//                self.inputPort = nil
//                iNode.removeInputEdge(edge: self)
//                withAnimation(.easeIn) {
//                    self.dataType = self.outputPort.dataType
//                }
//            }
//        }
//    }
//}
//


