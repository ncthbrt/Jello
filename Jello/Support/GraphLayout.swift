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
    static let nodeWidth: CGFloat = 200.0
    static let padding: CGFloat = 15.0
    static let cornerRadius: CGFloat = 20.0
    static let outputPortDiameter : CGFloat = 20.0
    static let inputPortDiameter : CGFloat = 17.0
    static let inputPortStrokeWidth : CGFloat = 3.0

    static func computeNodeHeight(inputPortsCount: Int, outputPortsCount: Int) -> CGFloat {
        return Self.headerHeight + JelloNode.portHeight * CGFloat(max(inputPortsCount, inputPortsCount))
    }
    
    static func getInputPortPositionOffset(index: UInt8, relativeTo: PortRelativeTo) -> CGPoint {
        switch relativeTo {
        case .nodeSpace:
            return CGPoint(x: JelloNode.padding + JelloNode.nodeWidth / 4, y: JelloNode.headerHeight) + CGPoint(x: 0, y: JelloNode.portHeight) * CGFloat(index)
        case .worldSpace:
            return CGPoint(x: JelloNode.padding, y: JelloNode.headerHeight) + CGPoint(x: 0, y: JelloNode.portHeight) * CGFloat(index)
        }
    }
    
    static func getOutputPortPositionOffset(index: UInt8, relativeTo: PortRelativeTo) -> CGPoint {
        switch relativeTo {
        case .nodeSpace:
            return CGPoint(x: JelloNode.nodeWidth - JelloNode.padding - JelloNode.nodeWidth / 4, y: JelloNode.headerHeight) + CGPoint(x: 0, y: JelloNode.portHeight) * CGFloat(index)
        case .worldSpace:
            return CGPoint(x: JelloNode.nodeWidth - JelloNode.padding, y: JelloNode.headerHeight) + CGPoint(x: 0, y: JelloNode.portHeight) * CGFloat(index)
        }
    }
    
    func getOutputPortWorldPosition(index: UInt8, inputPortCount: Int, outputPortCount: Int) -> CGPoint {
        return self.position - CGPoint(x: JelloNode.nodeWidth / 2, y: Self.computeNodeHeight(inputPortsCount: inputPortCount, outputPortsCount: outputPortCount) / 2) + Self.getOutputPortPositionOffset(index: index, relativeTo: .worldSpace) + CGPoint(x:  -(JelloNode.outputPortDiameter) / 2, y: -ceil(JelloNode.outputPortDiameter / 4))
    }
    
    func getInputPortWorldPosition(index: UInt8, inputPortCount: Int, outputPortCount: Int) -> CGPoint {
      return self.position - CGPoint(x: JelloNode.nodeWidth / 2, y: Self.computeNodeHeight(inputPortsCount: inputPortCount, outputPortsCount: outputPortCount) / 2) + Self.getInputPortPositionOffset(index: index, relativeTo: .worldSpace) + CGPoint(x: JelloNode.inputPortDiameter / 2, y: -ceil(JelloNode.inputPortDiameter / 4))
    }
}


extension JelloEdge {
    static let maxEdgeSnapDistance: CGFloat = 50.0
}



