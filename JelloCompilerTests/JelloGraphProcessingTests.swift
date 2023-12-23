//
//  JelloGraphProcessingTests.swift
//  JelloTests
//
//  Created by Natalie Cuthbert on 2023/12/22.
//

import Foundation
import XCTest
@testable import JelloCompilerStatic


class GenericTestNode : Node {
    public var id: UUID
    public var inputPorts: [InputPort]
    public var outputPorts: [OutputPort]
    public static func install() {}
    public var branchTags: Set<UUID>
    
    public init(id: UUID, inputPorts: [InputPort], outputPorts: [OutputPort]) {
        self.id = id
        self.inputPorts = inputPorts
        self.outputPorts = outputPorts
        self.branchTags = Set()
    }
    
    convenience init() {
        self.init(id: UUID(), inputPorts: [], outputPorts: [])
    }
}

final class JelloLabelBranchesTest: XCTestCase {
    var input: JelloCompilerInput? = nil
    var common: GenericTestNode? = nil
    var a: GenericTestNode? = nil
    var b: GenericTestNode? = nil
    var c: GenericTestNode? = nil
    var d: GenericTestNode? = nil
    var e: GenericTestNode? = nil
    var f: GenericTestNode? = nil
    var g: GenericTestNode? = nil
    var outputNode: PreviewOutput? = nil
    var ifElseNode: IfElseNode? = nil
    var lonely1: GenericTestNode? = nil
    var lonely2: GenericTestNode? = nil
    
    override func setUpWithError() throws {
        var graph = Graph()
        var outputInPort = InputPort()
        outputNode = PreviewOutput(id: UUID(), inputPort: outputInPort)
        var output = JelloCompilerInput.Output.previewOutput(outputNode!)

        
        outputInPort.node = outputNode
        outputNode!.inputPorts = [outputInPort]
        
        a = GenericTestNode()
        b = GenericTestNode()
        c = GenericTestNode()
        d = GenericTestNode()
        e = GenericTestNode()
        f = GenericTestNode()
        g = GenericTestNode()
        common = GenericTestNode()
        lonely1 = GenericTestNode()
        lonely2 = GenericTestNode()
        
        var condInputPort = InputPort()
        var ifTrueInputPort = InputPort()
        var ifFalseInputPort = InputPort()
        var ifElseOutputPort = OutputPort()
        ifElseNode = IfElseNode(id: UUID(), condition: condInputPort, ifTrue: ifTrueInputPort, ifFalse: ifFalseInputPort, outputPort: ifElseOutputPort)
        condInputPort.node = ifElseNode
        ifTrueInputPort.node = ifElseNode
        ifFalseInputPort.node = ifElseNode
        ifElseOutputPort.node = ifElseNode
       
        
        var commonInPort1 = InputPort()
        var commonInPort2 = InputPort()
        commonInPort1.node = common
        commonInPort2.node = common
        var commonOutPort = OutputPort()
        commonOutPort.node = common
        common!.inputPorts = [commonInPort1, commonInPort2]
        common!.outputPorts = [commonOutPort]
        
        var aInPort = InputPort()
        aInPort.node = a
        var aOutPort = OutputPort()
        aOutPort.node = a
        a!.inputPorts = [aInPort]
        a!.outputPorts = [aOutPort]
        
        var bInPort = InputPort()
        bInPort.node = b
        var bOutPort = OutputPort()
        bOutPort.node = b
        b!.inputPorts = [bInPort]
        b!.outputPorts = [bOutPort]
        
        var cInPort = InputPort()
        cInPort.node = c
        var cOutPort = OutputPort()
        cOutPort.node = c
        c!.inputPorts = [cInPort]
        c!.outputPorts = [cOutPort]
        
        var dInPort = InputPort()
        dInPort.node = d
        var dOutPort = OutputPort()
        dOutPort.node = d
        d!.inputPorts = [dInPort]
        d!.outputPorts = [dOutPort]
        
        var eInPort = InputPort()
        eInPort.node = e
        var eOutPort = OutputPort()
        eOutPort.node = e
        e!.inputPorts = [eInPort]
        e!.outputPorts = [eOutPort]
        
        var fInPort = InputPort()
        fInPort.node = f
        var fOutPort = OutputPort()
        fOutPort.node = f
        f!.inputPorts = [fInPort]
        f!.outputPorts = [fOutPort]
        
        var gInPort = InputPort()
        gInPort.node = g
        var gOutPort = OutputPort()
        gOutPort.node = g
        g!.inputPorts = [gInPort]
        g!.outputPorts = [gOutPort]
        
        var lonely1InPort = InputPort()
        lonely1InPort.node = lonely1
        var lonely1OutPort = OutputPort()
        lonely1OutPort.node = lonely1
        lonely1!.inputPorts = [lonely1InPort]
        lonely1!.outputPorts = [lonely1OutPort]
        
        var lonely2InPort = InputPort()
        lonely2InPort.node = lonely2
        var lonely2OutPort = OutputPort()
        lonely2OutPort.node = lonely2
        lonely2!.inputPorts = [lonely2InPort]
        lonely2!.outputPorts = [lonely2OutPort]
        
        var nodes: [Node] = [a!, b!, c!, d!, e!, f!, g!, outputNode!, ifElseNode!, common!, lonely1!, lonely2!]
        graph.nodes = nodes
        
        
        // Finally connect up the graph
        let aCommonEdge = Edge(inputPort: commonInPort1, outputPort: aOutPort)
        let faEdge = Edge(inputPort: aInPort, outputPort: fOutPort)
        let feEdge = Edge(inputPort: fInPort, outputPort: eOutPort)
        let geEdge = Edge(inputPort: eInPort, outputPort: gOutPort)
        let ebEdge = Edge(inputPort: bInPort, outputPort: eOutPort)
        let bTrueEdge = Edge(inputPort: ifTrueInputPort, outputPort: bOutPort)
        let cFalseEdge = Edge(inputPort: ifFalseInputPort, outputPort: cOutPort)
        let dcEdge = Edge(inputPort: cInPort, outputPort: dOutPort)
        let ifCommonEdge = Edge(inputPort: commonInPort2, outputPort: ifElseOutputPort)
        let commonOutEdge = Edge(inputPort: outputInPort, outputPort: commonOutPort)
        let lonely1lonely2Edge = Edge(inputPort: lonely2InPort, outputPort: lonely1OutPort)
        let eLonely1Edge = Edge(inputPort: lonely1InPort, outputPort: eOutPort)
        
        input = JelloCompilerInput(output: output, graph: graph)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testThatLabellingBranchesProducesExpectedResult() throws {
        labelBranches(input: input!)
        let mainBranchId = outputNode!.branchTags.first!
        let trueBranchId = ifElseNode!.trueBranchTag
        let falseBranchId = ifElseNode!.falseBranchTag
        XCTAssertEqual(lonely1?.branchTags, Set([]))
        XCTAssertEqual(lonely2?.branchTags, Set([]))
        XCTAssertEqual(a?.branchTags, Set([mainBranchId]))
        XCTAssertEqual(f?.branchTags, Set([mainBranchId]))
        XCTAssertEqual(ifElseNode?.branchTags, Set([mainBranchId]))
        XCTAssertEqual(c?.branchTags, Set([falseBranchId]))
        XCTAssertEqual(d?.branchTags, Set([falseBranchId]))
        XCTAssertEqual(b?.branchTags, Set([trueBranchId]))
        XCTAssertEqual(e?.branchTags, Set([trueBranchId, mainBranchId]))
        XCTAssertEqual(g?.branchTags, Set([trueBranchId, mainBranchId]))
    }
}

final class JelloPruneGraphTest: XCTestCase {
    var input: JelloCompilerInput? = nil
    var common: GenericTestNode? = nil
    var a: GenericTestNode? = nil
    var b: GenericTestNode? = nil
    var c: GenericTestNode? = nil
    var d: GenericTestNode? = nil
    var e: GenericTestNode? = nil
    var f: GenericTestNode? = nil
    var g: GenericTestNode? = nil
    var outputNode: PreviewOutput? = nil
    var ifElseNode: IfElseNode? = nil
    var lonely1: GenericTestNode? = nil
    var lonely2: GenericTestNode? = nil
    
    override func setUpWithError() throws {
        var graph = Graph()
        var outputInPort = InputPort()
        outputNode = PreviewOutput(id: UUID(), inputPort: outputInPort)
        var output = JelloCompilerInput.Output.previewOutput(outputNode!)

        
        outputInPort.node = outputNode
        outputNode!.inputPorts = [outputInPort]
        
        a = GenericTestNode()
        b = GenericTestNode()
        c = GenericTestNode()
        d = GenericTestNode()
        e = GenericTestNode()
        f = GenericTestNode()
        g = GenericTestNode()
        common = GenericTestNode()
        lonely1 = GenericTestNode()
        lonely2 = GenericTestNode()
        
        var condInputPort = InputPort()
        var ifTrueInputPort = InputPort()
        var ifFalseInputPort = InputPort()
        var ifElseOutputPort = OutputPort()
        ifElseNode = IfElseNode(id: UUID(), condition: condInputPort, ifTrue: ifTrueInputPort, ifFalse: ifFalseInputPort, outputPort: ifElseOutputPort)
        condInputPort.node = ifElseNode
        ifTrueInputPort.node = ifElseNode
        ifFalseInputPort.node = ifElseNode
        ifElseOutputPort.node = ifElseNode
       
        
        var commonInPort1 = InputPort()
        var commonInPort2 = InputPort()
        commonInPort1.node = common
        commonInPort2.node = common
        var commonOutPort = OutputPort()
        commonOutPort.node = common
        common!.inputPorts = [commonInPort1, commonInPort2]
        common!.outputPorts = [commonOutPort]
        
        var aInPort = InputPort()
        aInPort.node = a
        var aOutPort = OutputPort()
        aOutPort.node = a
        a!.inputPorts = [aInPort]
        a!.outputPorts = [aOutPort]
        
        var bInPort = InputPort()
        bInPort.node = b
        var bOutPort = OutputPort()
        bOutPort.node = b
        b!.inputPorts = [bInPort]
        b!.outputPorts = [bOutPort]
        
        var cInPort = InputPort()
        cInPort.node = c
        var cOutPort = OutputPort()
        cOutPort.node = c
        c!.inputPorts = [cInPort]
        c!.outputPorts = [cOutPort]
        
        var dInPort = InputPort()
        dInPort.node = d
        var dOutPort = OutputPort()
        dOutPort.node = d
        d!.inputPorts = [dInPort]
        d!.outputPorts = [dOutPort]
        
        var eInPort = InputPort()
        eInPort.node = e
        var eOutPort = OutputPort()
        eOutPort.node = e
        e!.inputPorts = [eInPort]
        e!.outputPorts = [eOutPort]
        
        var fInPort = InputPort()
        fInPort.node = f
        var fOutPort = OutputPort()
        fOutPort.node = f
        f!.inputPorts = [fInPort]
        f!.outputPorts = [fOutPort]
        
        var gInPort = InputPort()
        gInPort.node = g
        var gOutPort = OutputPort()
        gOutPort.node = g
        g!.inputPorts = [gInPort]
        g!.outputPorts = [gOutPort]
        
        var lonely1InPort = InputPort()
        lonely1InPort.node = lonely1
        var lonely1OutPort = OutputPort()
        lonely1OutPort.node = lonely1
        lonely1!.inputPorts = [lonely1InPort]
        lonely1!.outputPorts = [lonely1OutPort]
        
        var lonely2InPort = InputPort()
        lonely2InPort.node = lonely2
        var lonely2OutPort = OutputPort()
        lonely2OutPort.node = lonely2
        lonely2!.inputPorts = [lonely2InPort]
        lonely2!.outputPorts = [lonely2OutPort]
        
        var nodes: [Node] = [a!, b!, c!, d!, e!, f!, g!, outputNode!, ifElseNode!, common!, lonely1!, lonely2!]
        graph.nodes = nodes
        
        
        // Finally connect up the graph
        let aCommonEdge = Edge(inputPort: commonInPort1, outputPort: aOutPort)
        let faEdge = Edge(inputPort: aInPort, outputPort: fOutPort)
        let feEdge = Edge(inputPort: fInPort, outputPort: eOutPort)
        let geEdge = Edge(inputPort: eInPort, outputPort: gOutPort)
        let ebEdge = Edge(inputPort: bInPort, outputPort: eOutPort)
        let bTrueEdge = Edge(inputPort: ifTrueInputPort, outputPort: bOutPort)
        let cFalseEdge = Edge(inputPort: ifFalseInputPort, outputPort: cOutPort)
        let dcEdge = Edge(inputPort: cInPort, outputPort: dOutPort)
        let ifCommonEdge = Edge(inputPort: commonInPort2, outputPort: ifElseOutputPort)
        let commonOutEdge = Edge(inputPort: outputInPort, outputPort: commonOutPort)
        let lonely1lonely2Edge = Edge(inputPort: lonely2InPort, outputPort: lonely1OutPort)
        let eLonely1Edge = Edge(inputPort: lonely1InPort, outputPort: eOutPort)
        
        input = JelloCompilerInput(output: output, graph: graph)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testThatPruningGraphProducesExpectedResult(){
        labelBranches(input: input!)
        pruneGraph(input: input!)
        let nodes = input!.graph.nodes
        XCTAssert(!nodes.contains(where: {$0.id == lonely1!.id }))
        XCTAssert(!nodes.contains(where: {$0.id == lonely2!.id }))
        XCTAssert(nodes.contains(where: {$0.id == a!.id }))
        XCTAssert(nodes.contains(where: {$0.id == b!.id }))
        XCTAssert(nodes.contains(where: {$0.id == c!.id }))
        XCTAssert(nodes.contains(where: {$0.id == d!.id }))
        XCTAssert(nodes.contains(where: {$0.id == e!.id }))
        XCTAssert(nodes.contains(where: {$0.id == f!.id }))
        XCTAssert(nodes.contains(where: {$0.id == g!.id }))
        XCTAssert(nodes.contains(where: {$0.id == common!.id }))
        XCTAssert(nodes.contains(where: {$0.id == ifElseNode!.id }))
        XCTAssert(nodes.contains(where: {$0.id == outputNode!.id }))
    }
}

final class JelloTopologicallyOrderGraphTest: XCTestCase {
    var input: JelloCompilerInput? = nil
    var common: GenericTestNode? = nil
    var a: GenericTestNode? = nil
    var b: GenericTestNode? = nil
    var c: GenericTestNode? = nil
    var d: GenericTestNode? = nil
    var e: GenericTestNode? = nil
    var f: GenericTestNode? = nil
    var g: GenericTestNode? = nil
    var outputNode: PreviewOutput? = nil
    var ifElseNode: IfElseNode? = nil
    var lonely1: GenericTestNode? = nil
    var lonely2: GenericTestNode? = nil
    
    override func setUpWithError() throws {
        var graph = Graph()
        var outputInPort = InputPort()
        outputNode = PreviewOutput(id: UUID(), inputPort: outputInPort)
        var output = JelloCompilerInput.Output.previewOutput(outputNode!)

        
        outputInPort.node = outputNode
        outputNode!.inputPorts = [outputInPort]
        
        a = GenericTestNode()
        b = GenericTestNode()
        c = GenericTestNode()
        d = GenericTestNode()
        e = GenericTestNode()
        f = GenericTestNode()
        g = GenericTestNode()
        common = GenericTestNode()
        lonely1 = GenericTestNode()
        lonely2 = GenericTestNode()
        
        var condInputPort = InputPort()
        var ifTrueInputPort = InputPort()
        var ifFalseInputPort = InputPort()
        var ifElseOutputPort = OutputPort()
        ifElseNode = IfElseNode(id: UUID(), condition: condInputPort, ifTrue: ifTrueInputPort, ifFalse: ifFalseInputPort, outputPort: ifElseOutputPort)
        condInputPort.node = ifElseNode
        ifTrueInputPort.node = ifElseNode
        ifFalseInputPort.node = ifElseNode
        ifElseOutputPort.node = ifElseNode
       
        
        var commonInPort1 = InputPort()
        var commonInPort2 = InputPort()
        commonInPort1.node = common
        commonInPort2.node = common
        var commonOutPort = OutputPort()
        commonOutPort.node = common
        common!.inputPorts = [commonInPort1, commonInPort2]
        common!.outputPorts = [commonOutPort]
        
        var aInPort = InputPort()
        aInPort.node = a
        var aOutPort = OutputPort()
        aOutPort.node = a
        a!.inputPorts = [aInPort]
        a!.outputPorts = [aOutPort]
        
        var bInPort = InputPort()
        bInPort.node = b
        var bOutPort = OutputPort()
        bOutPort.node = b
        b!.inputPorts = [bInPort]
        b!.outputPorts = [bOutPort]
        
        var cInPort = InputPort()
        cInPort.node = c
        var cOutPort = OutputPort()
        cOutPort.node = c
        c!.inputPorts = [cInPort]
        c!.outputPorts = [cOutPort]
        
        var dInPort = InputPort()
        dInPort.node = d
        var dOutPort = OutputPort()
        dOutPort.node = d
        d!.inputPorts = [dInPort]
        d!.outputPorts = [dOutPort]
        
        var eInPort = InputPort()
        eInPort.node = e
        var eOutPort = OutputPort()
        eOutPort.node = e
        e!.inputPorts = [eInPort]
        e!.outputPorts = [eOutPort]
        
        var fInPort = InputPort()
        fInPort.node = f
        var fOutPort = OutputPort()
        fOutPort.node = f
        f!.inputPorts = [fInPort]
        f!.outputPorts = [fOutPort]
        
        var gInPort = InputPort()
        gInPort.node = g
        var gOutPort = OutputPort()
        gOutPort.node = g
        g!.inputPorts = [gInPort]
        g!.outputPorts = [gOutPort]
        
        var lonely1InPort = InputPort()
        lonely1InPort.node = lonely1
        var lonely1OutPort = OutputPort()
        lonely1OutPort.node = lonely1
        lonely1!.inputPorts = [lonely1InPort]
        lonely1!.outputPorts = [lonely1OutPort]
        
        var lonely2InPort = InputPort()
        lonely2InPort.node = lonely2
        var lonely2OutPort = OutputPort()
        lonely2OutPort.node = lonely2
        lonely2!.inputPorts = [lonely2InPort]
        lonely2!.outputPorts = [lonely2OutPort]
        
        var nodes: [Node] = [a!, b!, c!, d!, e!, f!, g!, outputNode!, ifElseNode!, common!, lonely1!, lonely2!]
        graph.nodes = nodes
        
        
        // Finally connect up the graph
        let aCommonEdge = Edge(inputPort: commonInPort1, outputPort: aOutPort)
        let faEdge = Edge(inputPort: aInPort, outputPort: fOutPort)
        let feEdge = Edge(inputPort: fInPort, outputPort: eOutPort)
        let geEdge = Edge(inputPort: eInPort, outputPort: gOutPort)
        let ebEdge = Edge(inputPort: bInPort, outputPort: eOutPort)
        let bTrueEdge = Edge(inputPort: ifTrueInputPort, outputPort: bOutPort)
        let cFalseEdge = Edge(inputPort: ifFalseInputPort, outputPort: cOutPort)
        let dcEdge = Edge(inputPort: cInPort, outputPort: dOutPort)
        let ifCommonEdge = Edge(inputPort: commonInPort2, outputPort: ifElseOutputPort)
        let commonOutEdge = Edge(inputPort: outputInPort, outputPort: commonOutPort)
        let lonely1lonely2Edge = Edge(inputPort: lonely2InPort, outputPort: lonely1OutPort)
        let eLonely1Edge = Edge(inputPort: lonely1InPort, outputPort: eOutPort)
        
        input = JelloCompilerInput(output: output, graph: graph)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testThatOrderingGraphProducesExpectedResult(){
        labelBranches(input: input!)
        pruneGraph(input: input!)
        topologicallyOrderGraph(input: input!)
        let nodes = input!.graph.nodes
        let aIndex = nodes.firstIndex(where: {$0.id == a?.id})!
        let bIndex = nodes.firstIndex(where: {$0.id == b?.id})!
        let cIndex = nodes.firstIndex(where: {$0.id == c?.id})!
        let dIndex = nodes.firstIndex(where: {$0.id == d?.id})!
        let eIndex = nodes.firstIndex(where: {$0.id == e?.id})!
        let fIndex = nodes.firstIndex(where: {$0.id == f?.id})!
        let gIndex = nodes.firstIndex(where: {$0.id == g?.id})!
        let ifElseIndex = nodes.firstIndex(where: {$0.id == ifElseNode?.id})!
        let commonIndex = nodes.firstIndex(where: {$0.id == common?.id})!
        let outputIndex = nodes.firstIndex(where: {$0.id == outputNode?.id})!
        
        XCTAssertLessThan(commonIndex, outputIndex)
        XCTAssertLessThan(aIndex, commonIndex)
        XCTAssertLessThan(fIndex, aIndex)
        XCTAssertLessThan(eIndex, fIndex)
        XCTAssertLessThan(gIndex, eIndex)
        XCTAssertLessThan(ifElseIndex, commonIndex)
        XCTAssertLessThan(bIndex, ifElseIndex)
        XCTAssertLessThan(cIndex, ifElseIndex)
        XCTAssertLessThan(dIndex, cIndex)
        XCTAssertLessThan(eIndex, bIndex)
    }

}

final class JelloDecomposeGraphTest: XCTestCase {
    var input: JelloCompilerInput? = nil
    var common: GenericTestNode? = nil
    var a: GenericTestNode? = nil
    var b: GenericTestNode? = nil
    var c: GenericTestNode? = nil
    var d: GenericTestNode? = nil
    var e: GenericTestNode? = nil
    var f: GenericTestNode? = nil
    var g: GenericTestNode? = nil
    var outputNode: PreviewOutput? = nil
    var ifElseNode: IfElseNode? = nil
    var lonely1: GenericTestNode? = nil
    var lonely2: GenericTestNode? = nil
    
    override func setUpWithError() throws {
        var graph = Graph()
        var outputInPort = InputPort()
        outputNode = PreviewOutput(id: UUID(), inputPort: outputInPort)
        var output = JelloCompilerInput.Output.previewOutput(outputNode!)

        
        outputInPort.node = outputNode
        outputNode!.inputPorts = [outputInPort]
        
        a = GenericTestNode()
        b = GenericTestNode()
        c = GenericTestNode()
        d = GenericTestNode()
        e = GenericTestNode()
        f = GenericTestNode()
        g = GenericTestNode()
        common = GenericTestNode()
        lonely1 = GenericTestNode()
        lonely2 = GenericTestNode()
        
        var condInputPort = InputPort()
        var ifTrueInputPort = InputPort()
        var ifFalseInputPort = InputPort()
        var ifElseOutputPort = OutputPort()
        ifElseNode = IfElseNode(id: UUID(), condition: condInputPort, ifTrue: ifTrueInputPort, ifFalse: ifFalseInputPort, outputPort: ifElseOutputPort)
        condInputPort.node = ifElseNode
        ifTrueInputPort.node = ifElseNode
        ifFalseInputPort.node = ifElseNode
        ifElseOutputPort.node = ifElseNode
       
        
        var commonInPort1 = InputPort()
        var commonInPort2 = InputPort()
        commonInPort1.node = common
        commonInPort2.node = common
        var commonOutPort = OutputPort()
        commonOutPort.node = common
        common!.inputPorts = [commonInPort1, commonInPort2]
        common!.outputPorts = [commonOutPort]
        
        var aInPort = InputPort()
        aInPort.node = a
        var aOutPort = OutputPort()
        aOutPort.node = a
        a!.inputPorts = [aInPort]
        a!.outputPorts = [aOutPort]
        
        var bInPort = InputPort()
        bInPort.node = b
        var bOutPort = OutputPort()
        bOutPort.node = b
        b!.inputPorts = [bInPort]
        b!.outputPorts = [bOutPort]
        
        var cInPort = InputPort()
        cInPort.node = c
        var cOutPort = OutputPort()
        cOutPort.node = c
        c!.inputPorts = [cInPort]
        c!.outputPorts = [cOutPort]
        
        var dInPort = InputPort()
        dInPort.node = d
        var dOutPort = OutputPort()
        dOutPort.node = d
        d!.inputPorts = [dInPort]
        d!.outputPorts = [dOutPort]
        
        var eInPort = InputPort()
        eInPort.node = e
        var eOutPort = OutputPort()
        eOutPort.node = e
        e!.inputPorts = [eInPort]
        e!.outputPorts = [eOutPort]
        
        var fInPort = InputPort()
        fInPort.node = f
        var fOutPort = OutputPort()
        fOutPort.node = f
        f!.inputPorts = [fInPort]
        f!.outputPorts = [fOutPort]
        
        var gInPort = InputPort()
        gInPort.node = g
        var gOutPort = OutputPort()
        gOutPort.node = g
        g!.inputPorts = [gInPort]
        g!.outputPorts = [gOutPort]
        
        var lonely1InPort = InputPort()
        lonely1InPort.node = lonely1
        var lonely1OutPort = OutputPort()
        lonely1OutPort.node = lonely1
        lonely1!.inputPorts = [lonely1InPort]
        lonely1!.outputPorts = [lonely1OutPort]
        
        var lonely2InPort = InputPort()
        lonely2InPort.node = lonely2
        var lonely2OutPort = OutputPort()
        lonely2OutPort.node = lonely2
        lonely2!.inputPorts = [lonely2InPort]
        lonely2!.outputPorts = [lonely2OutPort]
        
        var nodes: [Node] = [a!, b!, c!, d!, e!, f!, g!, outputNode!, ifElseNode!, common!, lonely1!, lonely2!]
        graph.nodes = nodes
        
        
        // Finally connect up the graph
        let aCommonEdge = Edge(inputPort: commonInPort1, outputPort: aOutPort)
        let faEdge = Edge(inputPort: aInPort, outputPort: fOutPort)
        let feEdge = Edge(inputPort: fInPort, outputPort: eOutPort)
        let geEdge = Edge(inputPort: eInPort, outputPort: gOutPort)
        let ebEdge = Edge(inputPort: bInPort, outputPort: eOutPort)
        let bTrueEdge = Edge(inputPort: ifTrueInputPort, outputPort: bOutPort)
        let cFalseEdge = Edge(inputPort: ifFalseInputPort, outputPort: cOutPort)
        let dcEdge = Edge(inputPort: cInPort, outputPort: dOutPort)
        let ifCommonEdge = Edge(inputPort: commonInPort2, outputPort: ifElseOutputPort)
        let commonOutEdge = Edge(inputPort: outputInPort, outputPort: commonOutPort)
        let lonely1lonely2Edge = Edge(inputPort: lonely2InPort, outputPort: lonely1OutPort)
        let eLonely1Edge = Edge(inputPort: lonely1InPort, outputPort: eOutPort)
        
        input = JelloCompilerInput(output: output, graph: graph)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testThatDecomposingGraphProducesExpectedResult(){
        labelBranches(input: input!)
        pruneGraph(input: input!)
        topologicallyOrderGraph(input: input!)
        decomposeGraph(input: input!)
        let trueBranchId = ifElseNode!.trueBranchTag
        let falseBranchId = ifElseNode!.falseBranchTag
        let trueBranchNodes = ifElseNode!.subNodes[trueBranchId]!
        let falseBranchNodes = ifElseNode!.subNodes[falseBranchId]!
        
        XCTAssertEqual(trueBranchNodes.map({$0.id}), [b!.id])
        XCTAssertEqual(falseBranchNodes.map({$0.id}), [d!.id, c!.id])
    }
}


