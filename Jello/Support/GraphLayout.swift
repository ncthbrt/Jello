import SwiftUI
import OrderedCollections
import Collections



extension JelloEdge {
    static let maxEdgeSnapDistance: Float = 50.0
}



extension JelloNode {
    static let standardNodeWidth = 200.0
    static let headerHeight: CGFloat = 60.0
    static let portHeight: CGFloat = 30.0
    static let padding: CGFloat = 15.0
    static let cornerRadius: CGFloat = 20.0
    static let outputPortDiameter : CGFloat = 20.0
    static let inputPortDiameter : CGFloat = 17.0
    static let inputPortStrokeWidth : CGFloat = 3.0

    static func getStandardNodeHeight(inputPortsCount: Int, outputPortsCount: Int) -> CGFloat {
        return Self.headerHeight + JelloNode.portHeight * CGFloat(max(inputPortsCount, inputPortsCount))
    }
    
    static func getStandardInputPortPositionOffset(index: UInt8) -> CGPoint {
        return CGPoint(x: JelloNode.padding, y: JelloNode.headerHeight) + CGPoint(x: 0, y: JelloNode.portHeight) * CGFloat(index)
    }
    
    static func getStandardOutputPortPositionOffset(index: UInt8) -> CGPoint {
        return CGPoint(x: JelloNode.standardNodeWidth - JelloNode.padding, y: JelloNode.headerHeight) + CGPoint(x: 0, y: JelloNode.portHeight) * CGFloat(index)
    }
}
