import SwiftUI
import OrderedCollections
import Collections

extension JelloNode {
    static let standardNodeWidth = 200.0
    static let headerHeight: CGFloat = 60.0
    static let portHeight: CGFloat = 30.0
    static let padding: CGFloat = 20.0
    static let cornerRadius: CGFloat = 20.0
    static let outputPortDiameter : CGFloat = 20.0
    static let inputPortDiameter : CGFloat = 17.0
    static let inputPortStrokeWidth : CGFloat = 3.0

    static func computeNodeHeight(inputPortsCount: Int, outputPortsCount: Int) -> CGFloat {
        return Self.headerHeight + JelloNode.portHeight * CGFloat(max(inputPortsCount, inputPortsCount))
    }
    
    static func getStandardInputPortPositionOffset(index: UInt8) -> CGPoint {
        return CGPoint(x: JelloNode.padding, y: JelloNode.headerHeight) + CGPoint(x: 0, y: JelloNode.portHeight) * CGFloat(index)
    }
    
    static func getStandardOutputPortPositionOffset(index: UInt8) -> CGPoint {
        return CGPoint(x: JelloNode.standardNodeWidth - JelloNode.padding, y: JelloNode.headerHeight) + CGPoint(x: 0, y: JelloNode.portHeight) * CGFloat(index)
    }
        
//    func getOutputPortWorldPosition(index: UInt8, inputPortCount: Int, outputPortCount: Int) -> CGPoint {
//        return self.position - CGPoint(x: JelloNode.nodeWidth / 2, y: Self.computeNodeHeight(inputPortsCount: inputPortCount, outputPortsCount: outputPortCount) / 2) + Self.getOutputPortPositionOffset(index: index, relativeTo: .worldSpace) + CGPoint(x:  -(JelloNode.outputPortDiameter) / 2, y: -ceil(JelloNode.outputPortDiameter / 4))
//    }
//    
//    func getInputPortWorldPosition(index: UInt8, inputPortCount: Int, outputPortCount: Int) -> CGPoint {
//      return self.position - CGPoint(x: JelloNode.nodeWidth / 2, y: Self.computeNodeHeight(inputPortsCount: inputPortCount, outputPortsCount: outputPortCount) / 2) + Self.getInputPortPositionOffset(index: index, relativeTo: .worldSpace) + CGPoint(x: JelloNode.inputPortDiameter / 2, y: -ceil(JelloNode.inputPortDiameter / 4))
//    }
}


extension JelloEdge {
    static let maxEdgeSnapDistance: Float = 50.0
}
