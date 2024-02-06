////
////  JelloGraphProcessingTests.swift
////  JelloTests
////
////  Created by Natalie Cuthbert on 2023/12/22.
////
//
//import Foundation
//import XCTest
//@testable import JelloCompilerStatic
//
//class GenericTestNode : CompilerNode {
//    public var id: UUID
//    public var inputPorts: [InputCompilerPort]
//    public var outputPorts: [OutputCompilerPort]
//    public func install() {}
//    public func writeVertex(){}
//    public func write(){}
//    public var branchTags: Set<UUID>
//    public var constraints: [PortConstraint] = []
//    
//
//    public init(id: UUID, inputPorts: [InputCompilerPort], outputPorts: [OutputCompilerPort]) {
//        self.id = id
//        self.inputPorts = inputPorts
//        self.outputPorts = outputPorts
//        self.branchTags = Set()
//    }
//    
//    convenience init() {
//        self.init(id: UUID(), inputPorts: [], outputPorts: [])
//    }
//}
//
//final class JelloLabelBranchesTest: XCTestCase {
//    var input: JelloCompilerInput? = nil
//    var common: GenericTestNode? = nil
//    var a: GenericTestNode? = nil
//    var b: GenericTestNode? = nil
//    var c: GenericTestNode? = nil
//    var d: GenericTestNode? = nil
//    var e: GenericTestNode? = nil
//    var f: GenericTestNode? = nil
//    var g: GenericTestNode? = nil
//    var outputNode: PreviewOutputCompilerNode? = nil
//    var ifElseNode: IfElseCompilerNode? = nil
//    var lonely1: GenericTestNode? = nil
//    var lonely2: GenericTestNode? = nil
//    
//    override func setUpWithError() throws {
//        var graph = CompilerGraph()
//        var outputInPort = InputCompilerPort()
//        outputNode = PreviewOutputCompilerNode(id: UUID(), inputPort: outputInPort)
//        var output = JelloCompilerInput.Output.previewOutput(outputNode!)
//
//        
//        outputInPort.node = outputNode
//        outputNode!.inputPorts = [outputInPort]
//        
//        a = GenericTestNode()
//        b = GenericTestNode()
//        c = GenericTestNode()
//        d = GenericTestNode()
//        e = GenericTestNode()
//        f = GenericTestNode()
//        g = GenericTestNode()
//        common = GenericTestNode()
//        lonely1 = GenericTestNode()
//        lonely2 = GenericTestNode()
//        
//        var condInputPort = InputCompilerPort()
//        var ifTrueInputPort = InputCompilerPort()
//        var ifFalseInputPort = InputCompilerPort()
//        var ifElseOutputPort = OutputCompilerPort()
//        ifElseNode = IfElseCompilerNode(id: UUID(), condition: condInputPort, ifTrue: ifTrueInputPort, ifFalse: ifFalseInputPort, outputPort: ifElseOutputPort)
//        condInputPort.node = ifElseNode
//        ifTrueInputPort.node = ifElseNode
//        ifFalseInputPort.node = ifElseNode
//        ifElseOutputPort.node = ifElseNode
//       
//        
//        var commonInPort1 = InputCompilerPort()
//        var commonInPort2 = InputCompilerPort()
//        commonInPort1.node = common
//        commonInPort2.node = common
//        var commonOutPort = OutputCompilerPort()
//        commonOutPort.node = common
//        common!.inputPorts = [commonInPort1, commonInPort2]
//        common!.outputPorts = [commonOutPort]
//        
//        var aInPort = InputCompilerPort()
//        aInPort.node = a
//        var aOutPort = OutputCompilerPort()
//        aOutPort.node = a
//        a!.inputPorts = [aInPort]
//        a!.outputPorts = [aOutPort]
//        
//        var bInPort = InputCompilerPort()
//        bInPort.node = b
//        var bOutPort = OutputCompilerPort()
//        bOutPort.node = b
//        b!.inputPorts = [bInPort]
//        b!.outputPorts = [bOutPort]
//        
//        var cInPort = InputCompilerPort()
//        cInPort.node = c
//        var cOutPort = OutputCompilerPort()
//        cOutPort.node = c
//        c!.inputPorts = [cInPort]
//        c!.outputPorts = [cOutPort]
//        
//        var dInPort = InputCompilerPort()
//        dInPort.node = d
//        var dOutPort = OutputCompilerPort()
//        dOutPort.node = d
//        d!.inputPorts = [dInPort]
//        d!.outputPorts = [dOutPort]
//        
//        var eInPort = InputCompilerPort()
//        eInPort.node = e
//        var eOutPort = OutputCompilerPort()
//        eOutPort.node = e
//        e!.inputPorts = [eInPort]
//        e!.outputPorts = [eOutPort]
//        
//        var fInPort = InputCompilerPort()
//        fInPort.node = f
//        var fOutPort = OutputCompilerPort()
//        fOutPort.node = f
//        f!.inputPorts = [fInPort]
//        f!.outputPorts = [fOutPort]
//        
//        var gInPort = InputCompilerPort()
//        gInPort.node = g
//        var gOutPort = OutputCompilerPort()
//        gOutPort.node = g
//        g!.inputPorts = [gInPort]
//        g!.outputPorts = [gOutPort]
//        
//        var lonely1InPort = InputCompilerPort()
//        lonely1InPort.node = lonely1
//        var lonely1OutPort = OutputCompilerPort()
//        lonely1OutPort.node = lonely1
//        lonely1!.inputPorts = [lonely1InPort]
//        lonely1!.outputPorts = [lonely1OutPort]
//        
//        var lonely2InPort = InputCompilerPort()
//        lonely2InPort.node = lonely2
//        var lonely2OutPort = OutputCompilerPort()
//        lonely2OutPort.node = lonely2
//        lonely2!.inputPorts = [lonely2InPort]
//        lonely2!.outputPorts = [lonely2OutPort]
//        
//        var nodes: [CompilerNode] = [a!, b!, c!, d!, e!, f!, g!, outputNode!, ifElseNode!, common!, lonely1!, lonely2!]
//        graph.nodes = nodes
//        
//        
//        // Finally connect up the graph
//        let aCommonEdge = CompilerEdge(inputPort: commonInPort1, outputPort: aOutPort)
//        let faEdge = CompilerEdge(inputPort: aInPort, outputPort: fOutPort)
//        let feEdge = CompilerEdge(inputPort: fInPort, outputPort: eOutPort)
//        let geEdge = CompilerEdge(inputPort: eInPort, outputPort: gOutPort)
//        let ebEdge = CompilerEdge(inputPort: bInPort, outputPort: eOutPort)
//        let bTrueEdge = CompilerEdge(inputPort: ifTrueInputPort, outputPort: bOutPort)
//        let cFalseEdge = CompilerEdge(inputPort: ifFalseInputPort, outputPort: cOutPort)
//        let dcEdge = CompilerEdge(inputPort: cInPort, outputPort: dOutPort)
//        let ifCommonEdge = CompilerEdge(inputPort: commonInPort2, outputPort: ifElseOutputPort)
//        let commonOutEdge = CompilerEdge(inputPort: outputInPort, outputPort: commonOutPort)
//        let lonely1lonely2Edge = CompilerEdge(inputPort: lonely2InPort, outputPort: lonely1OutPort)
//        let eLonely1Edge = CompilerEdge(inputPort: lonely1InPort, outputPort: eOutPort)
//        
//        input = JelloCompilerInput(output: output, graph: graph)
//    }
//
//    
//    func testThatLabellingBranchesProducesExpectedResult() throws {
//        labelBranches(input: input!)
//        let mainBranchId = outputNode!.branchTags.first!
//        let trueBranchId = ifElseNode!.trueBranchTag
//        let falseBranchId = ifElseNode!.falseBranchTag
//        XCTAssertEqual(lonely1?.branchTags, Set([]))
//        XCTAssertEqual(lonely2?.branchTags, Set([]))
//        XCTAssertEqual(a?.branchTags, Set([mainBranchId]))
//        XCTAssertEqual(f?.branchTags, Set([mainBranchId]))
//        XCTAssertEqual(ifElseNode?.branchTags, Set([mainBranchId]))
//        XCTAssertEqual(c?.branchTags, Set([falseBranchId]))
//        XCTAssertEqual(d?.branchTags, Set([falseBranchId]))
//        XCTAssertEqual(b?.branchTags, Set([trueBranchId]))
//        XCTAssertEqual(e?.branchTags, Set([trueBranchId, mainBranchId]))
//        XCTAssertEqual(g?.branchTags, Set([trueBranchId, mainBranchId]))
//    }
//}
//
//final class JelloPruneGraphTest: XCTestCase {
//    var input: JelloCompilerInput? = nil
//    var common: GenericTestNode? = nil
//    var a: GenericTestNode? = nil
//    var b: GenericTestNode? = nil
//    var c: GenericTestNode? = nil
//    var d: GenericTestNode? = nil
//    var e: GenericTestNode? = nil
//    var f: GenericTestNode? = nil
//    var g: GenericTestNode? = nil
//    var outputNode: PreviewOutputCompilerNode? = nil
//    var ifElseNode: IfElseCompilerNode? = nil
//    var lonely1: GenericTestNode? = nil
//    var lonely2: GenericTestNode? = nil
//    
//    override func setUpWithError() throws {
//        var graph = CompilerGraph()
//        var outputInPort = InputCompilerPort()
//        outputNode = PreviewOutputCompilerNode(id: UUID(), inputPort: outputInPort)
//        var output = JelloCompilerInput.Output.previewOutput(outputNode!)
//
//        
//        outputInPort.node = outputNode
//        outputNode!.inputPorts = [outputInPort]
//        
//        a = GenericTestNode()
//        b = GenericTestNode()
//        c = GenericTestNode()
//        d = GenericTestNode()
//        e = GenericTestNode()
//        f = GenericTestNode()
//        g = GenericTestNode()
//        common = GenericTestNode()
//        lonely1 = GenericTestNode()
//        lonely2 = GenericTestNode()
//        
//        var condInputPort = InputCompilerPort()
//        var ifTrueInputPort = InputCompilerPort()
//        var ifFalseInputPort = InputCompilerPort()
//        var ifElseOutputPort = OutputCompilerPort()
//        ifElseNode = IfElseCompilerNode(id: UUID(), condition: condInputPort, ifTrue: ifTrueInputPort, ifFalse: ifFalseInputPort, outputPort: ifElseOutputPort)
//        condInputPort.node = ifElseNode
//        ifTrueInputPort.node = ifElseNode
//        ifFalseInputPort.node = ifElseNode
//        ifElseOutputPort.node = ifElseNode
//       
//        
//        var commonInPort1 = InputCompilerPort()
//        var commonInPort2 = InputCompilerPort()
//        commonInPort1.node = common
//        commonInPort2.node = common
//        var commonOutPort = OutputCompilerPort()
//        commonOutPort.node = common
//        common!.inputPorts = [commonInPort1, commonInPort2]
//        common!.outputPorts = [commonOutPort]
//        
//        var aInPort = InputCompilerPort()
//        aInPort.node = a
//        var aOutPort = OutputCompilerPort()
//        aOutPort.node = a
//        a!.inputPorts = [aInPort]
//        a!.outputPorts = [aOutPort]
//        
//        var bInPort = InputCompilerPort()
//        bInPort.node = b
//        var bOutPort = OutputCompilerPort()
//        bOutPort.node = b
//        b!.inputPorts = [bInPort]
//        b!.outputPorts = [bOutPort]
//        
//        var cInPort = InputCompilerPort()
//        cInPort.node = c
//        var cOutPort = OutputCompilerPort()
//        cOutPort.node = c
//        c!.inputPorts = [cInPort]
//        c!.outputPorts = [cOutPort]
//        
//        var dInPort = InputCompilerPort()
//        dInPort.node = d
//        var dOutPort = OutputCompilerPort()
//        dOutPort.node = d
//        d!.inputPorts = [dInPort]
//        d!.outputPorts = [dOutPort]
//        
//        var eInPort = InputCompilerPort()
//        eInPort.node = e
//        var eOutPort = OutputCompilerPort()
//        eOutPort.node = e
//        e!.inputPorts = [eInPort]
//        e!.outputPorts = [eOutPort]
//        
//        var fInPort = InputCompilerPort()
//        fInPort.node = f
//        var fOutPort = OutputCompilerPort()
//        fOutPort.node = f
//        f!.inputPorts = [fInPort]
//        f!.outputPorts = [fOutPort]
//        
//        var gInPort = InputCompilerPort()
//        gInPort.node = g
//        var gOutPort = OutputCompilerPort()
//        gOutPort.node = g
//        g!.inputPorts = [gInPort]
//        g!.outputPorts = [gOutPort]
//        
//        var lonely1InPort = InputCompilerPort()
//        lonely1InPort.node = lonely1
//        var lonely1OutPort = OutputCompilerPort()
//        lonely1OutPort.node = lonely1
//        lonely1!.inputPorts = [lonely1InPort]
//        lonely1!.outputPorts = [lonely1OutPort]
//        
//        var lonely2InPort = InputCompilerPort()
//        lonely2InPort.node = lonely2
//        var lonely2OutPort = OutputCompilerPort()
//        lonely2OutPort.node = lonely2
//        lonely2!.inputPorts = [lonely2InPort]
//        lonely2!.outputPorts = [lonely2OutPort]
//        
//        var nodes: [CompilerNode] = [a!, b!, c!, d!, e!, f!, g!, outputNode!, ifElseNode!, common!, lonely1!, lonely2!]
//        graph.nodes = nodes
//        
//        
//        // Finally connect up the graph
//        let aCommonEdge = CompilerEdge(inputPort: commonInPort1, outputPort: aOutPort)
//        let faEdge = CompilerEdge(inputPort: aInPort, outputPort: fOutPort)
//        let feEdge = CompilerEdge(inputPort: fInPort, outputPort: eOutPort)
//        let geEdge = CompilerEdge(inputPort: eInPort, outputPort: gOutPort)
//        let ebEdge = CompilerEdge(inputPort: bInPort, outputPort: eOutPort)
//        let bTrueEdge = CompilerEdge(inputPort: ifTrueInputPort, outputPort: bOutPort)
//        let cFalseEdge = CompilerEdge(inputPort: ifFalseInputPort, outputPort: cOutPort)
//        let dcEdge = CompilerEdge(inputPort: cInPort, outputPort: dOutPort)
//        let ifCommonEdge = CompilerEdge(inputPort: commonInPort2, outputPort: ifElseOutputPort)
//        let commonOutEdge = CompilerEdge(inputPort: outputInPort, outputPort: commonOutPort)
//        let lonely1lonely2Edge = CompilerEdge(inputPort: lonely2InPort, outputPort: lonely1OutPort)
//        let eLonely1Edge = CompilerEdge(inputPort: lonely1InPort, outputPort: eOutPort)
//        
//        input = JelloCompilerInput(output: output, graph: graph)
//    }
//    
//    func testThatPruningGraphProducesExpectedResult(){
//        labelBranches(input: input!)
//        pruneGraph(input: input!)
//        let nodes = input!.graph.nodes
//        XCTAssert(!nodes.contains(where: {$0.id == lonely1!.id }))
//        XCTAssert(!nodes.contains(where: {$0.id == lonely2!.id }))
//        XCTAssert(nodes.contains(where: {$0.id == a!.id }))
//        XCTAssert(nodes.contains(where: {$0.id == b!.id }))
//        XCTAssert(nodes.contains(where: {$0.id == c!.id }))
//        XCTAssert(nodes.contains(where: {$0.id == d!.id }))
//        XCTAssert(nodes.contains(where: {$0.id == e!.id }))
//        XCTAssert(nodes.contains(where: {$0.id == f!.id }))
//        XCTAssert(nodes.contains(where: {$0.id == g!.id }))
//        XCTAssert(nodes.contains(where: {$0.id == common!.id }))
//        XCTAssert(nodes.contains(where: {$0.id == ifElseNode!.id }))
//        XCTAssert(nodes.contains(where: {$0.id == outputNode!.id }))
//    }
//}
//
//final class JelloTopologicallyOrderGraphTest: XCTestCase {
//    var input: JelloCompilerInput? = nil
//    var common: GenericTestNode? = nil
//    var a: GenericTestNode? = nil
//    var b: GenericTestNode? = nil
//    var c: GenericTestNode? = nil
//    var d: GenericTestNode? = nil
//    var e: GenericTestNode? = nil
//    var f: GenericTestNode? = nil
//    var g: GenericTestNode? = nil
//    var outputNode: PreviewOutputCompilerNode? = nil
//    var ifElseNode: IfElseCompilerNode? = nil
//    var lonely1: GenericTestNode? = nil
//    var lonely2: GenericTestNode? = nil
//    
//    override func setUpWithError() throws {
//        var graph = CompilerGraph()
//        var outputInPort = InputCompilerPort()
//        outputNode = PreviewOutputCompilerNode(id: UUID(), inputPort: outputInPort)
//        var output = JelloCompilerInput.Output.previewOutput(outputNode!)
//
//        
//        outputInPort.node = outputNode
//        outputNode!.inputPorts = [outputInPort]
//        
//        a = GenericTestNode()
//        b = GenericTestNode()
//        c = GenericTestNode()
//        d = GenericTestNode()
//        e = GenericTestNode()
//        f = GenericTestNode()
//        g = GenericTestNode()
//        common = GenericTestNode()
//        lonely1 = GenericTestNode()
//        lonely2 = GenericTestNode()
//        
//        var condInputPort = InputCompilerPort()
//        var ifTrueInputPort = InputCompilerPort()
//        var ifFalseInputPort = InputCompilerPort()
//        var ifElseOutputPort = OutputCompilerPort()
//        ifElseNode = IfElseCompilerNode(id: UUID(), condition: condInputPort, ifTrue: ifTrueInputPort, ifFalse: ifFalseInputPort, outputPort: ifElseOutputPort)
//        condInputPort.node = ifElseNode
//        ifTrueInputPort.node = ifElseNode
//        ifFalseInputPort.node = ifElseNode
//        ifElseOutputPort.node = ifElseNode
//       
//        
//        var commonInPort1 = InputCompilerPort()
//        var commonInPort2 = InputCompilerPort()
//        commonInPort1.node = common
//        commonInPort2.node = common
//        var commonOutPort = OutputCompilerPort()
//        commonOutPort.node = common
//        common!.inputPorts = [commonInPort1, commonInPort2]
//        common!.outputPorts = [commonOutPort]
//        
//        var aInPort = InputCompilerPort()
//        aInPort.node = a
//        var aOutPort = OutputCompilerPort()
//        aOutPort.node = a
//        a!.inputPorts = [aInPort]
//        a!.outputPorts = [aOutPort]
//        
//        var bInPort = InputCompilerPort()
//        bInPort.node = b
//        var bOutPort = OutputCompilerPort()
//        bOutPort.node = b
//        b!.inputPorts = [bInPort]
//        b!.outputPorts = [bOutPort]
//        
//        var cInPort = InputCompilerPort()
//        cInPort.node = c
//        var cOutPort = OutputCompilerPort()
//        cOutPort.node = c
//        c!.inputPorts = [cInPort]
//        c!.outputPorts = [cOutPort]
//        
//        var dInPort = InputCompilerPort()
//        dInPort.node = d
//        var dOutPort = OutputCompilerPort()
//        dOutPort.node = d
//        d!.inputPorts = [dInPort]
//        d!.outputPorts = [dOutPort]
//        
//        var eInPort = InputCompilerPort()
//        eInPort.node = e
//        var eOutPort = OutputCompilerPort()
//        eOutPort.node = e
//        e!.inputPorts = [eInPort]
//        e!.outputPorts = [eOutPort]
//        
//        var fInPort = InputCompilerPort()
//        fInPort.node = f
//        var fOutPort = OutputCompilerPort()
//        fOutPort.node = f
//        f!.inputPorts = [fInPort]
//        f!.outputPorts = [fOutPort]
//        
//        var gInPort = InputCompilerPort()
//        gInPort.node = g
//        var gOutPort = OutputCompilerPort()
//        gOutPort.node = g
//        g!.inputPorts = [gInPort]
//        g!.outputPorts = [gOutPort]
//        
//        var lonely1InPort = InputCompilerPort()
//        lonely1InPort.node = lonely1
//        var lonely1OutPort = OutputCompilerPort()
//        lonely1OutPort.node = lonely1
//        lonely1!.inputPorts = [lonely1InPort]
//        lonely1!.outputPorts = [lonely1OutPort]
//        
//        var lonely2InPort = InputCompilerPort()
//        lonely2InPort.node = lonely2
//        var lonely2OutPort = OutputCompilerPort()
//        lonely2OutPort.node = lonely2
//        lonely2!.inputPorts = [lonely2InPort]
//        lonely2!.outputPorts = [lonely2OutPort]
//        
//        var nodes: [CompilerNode] = [a!, b!, c!, d!, e!, f!, g!, outputNode!, ifElseNode!, common!, lonely1!, lonely2!]
//        graph.nodes = nodes
//        
//        
//        // Finally connect up the graph
//        let aCommonEdge = CompilerEdge(inputPort: commonInPort1, outputPort: aOutPort)
//        let faEdge = CompilerEdge(inputPort: aInPort, outputPort: fOutPort)
//        let feEdge = CompilerEdge(inputPort: fInPort, outputPort: eOutPort)
//        let geEdge = CompilerEdge(inputPort: eInPort, outputPort: gOutPort)
//        let ebEdge = CompilerEdge(inputPort: bInPort, outputPort: eOutPort)
//        let bTrueEdge = CompilerEdge(inputPort: ifTrueInputPort, outputPort: bOutPort)
//        let cFalseEdge = CompilerEdge(inputPort: ifFalseInputPort, outputPort: cOutPort)
//        let dcEdge = CompilerEdge(inputPort: cInPort, outputPort: dOutPort)
//        let ifCommonEdge = CompilerEdge(inputPort: commonInPort2, outputPort: ifElseOutputPort)
//        let commonOutEdge = CompilerEdge(inputPort: outputInPort, outputPort: commonOutPort)
//        let lonely1lonely2Edge = CompilerEdge(inputPort: lonely2InPort, outputPort: lonely1OutPort)
//        let eLonely1Edge = CompilerEdge(inputPort: lonely1InPort, outputPort: eOutPort)
//        
//        input = JelloCompilerInput(output: output, graph: graph)
//    }
//
//    
//    func testThatOrderingGraphProducesExpectedResult(){
//        labelBranches(input: input!)
//        pruneGraph(input: input!)
//        topologicallyOrderGraph(input: input!)
//        let nodes = input!.graph.nodes
//        let aIndex = nodes.firstIndex(where: {$0.id == a?.id})!
//        let bIndex = nodes.firstIndex(where: {$0.id == b?.id})!
//        let cIndex = nodes.firstIndex(where: {$0.id == c?.id})!
//        let dIndex = nodes.firstIndex(where: {$0.id == d?.id})!
//        let eIndex = nodes.firstIndex(where: {$0.id == e?.id})!
//        let fIndex = nodes.firstIndex(where: {$0.id == f?.id})!
//        let gIndex = nodes.firstIndex(where: {$0.id == g?.id})!
//        let ifElseIndex = nodes.firstIndex(where: {$0.id == ifElseNode?.id})!
//        let commonIndex = nodes.firstIndex(where: {$0.id == common?.id})!
//        let outputIndex = nodes.firstIndex(where: {$0.id == outputNode?.id})!
//        
//        XCTAssertLessThan(commonIndex, outputIndex)
//        XCTAssertLessThan(aIndex, commonIndex)
//        XCTAssertLessThan(fIndex, aIndex)
//        XCTAssertLessThan(eIndex, fIndex)
//        XCTAssertLessThan(gIndex, eIndex)
//        XCTAssertLessThan(ifElseIndex, commonIndex)
//        XCTAssertLessThan(bIndex, ifElseIndex)
//        XCTAssertLessThan(cIndex, ifElseIndex)
//        XCTAssertLessThan(dIndex, cIndex)
//        XCTAssertLessThan(eIndex, bIndex)
//    }
//
//}
//
//final class JelloConcretiseTypesGraphTest: XCTestCase {
//    var input: JelloCompilerInput? = nil
//    var outputNode: PreviewOutputCompilerNode? = nil
//    var a: GenericTestNode? = nil
//    var b: GenericTestNode? = nil
//    var c: GenericTestNode? = nil
//    var d: GenericTestNode? = nil
//    var e: GenericTestNode? = nil
//    var f: GenericTestNode? = nil
//    var g: GenericTestNode? = nil
//    var ifElseNode: IfElseCompilerNode? = nil
//    
//    override func setUpWithError() throws {
//        var graph = CompilerGraph()
//        var outputInPort = InputCompilerPort()
//        outputNode = PreviewOutputCompilerNode(id: UUID(), inputPort: outputInPort)
//        var output = JelloCompilerInput.Output.previewOutput(outputNode!)
//        
//        a = GenericTestNode()
//        b = GenericTestNode()
//        c = GenericTestNode()
//        d = GenericTestNode()
//        e = GenericTestNode()
//        f = GenericTestNode()
//        g = GenericTestNode()
//        
//        var condInputPort = InputCompilerPort()
//        var ifTrueInputPort = InputCompilerPort()
//        var ifFalseInputPort = InputCompilerPort()
//        var ifElseOutputPort = OutputCompilerPort()
//        ifElseNode = IfElseCompilerNode(id: UUID(), condition: condInputPort, ifTrue: ifTrueInputPort, ifFalse: ifFalseInputPort, outputPort: ifElseOutputPort)
//        condInputPort.node = ifElseNode
//        ifTrueInputPort.node = ifElseNode
//        ifFalseInputPort.node = ifElseNode
//        ifElseOutputPort.node = ifElseNode
//        
//        var aInPort = InputCompilerPort()
//        aInPort.node = a
//        var aOutPort = OutputCompilerPort()
//        aOutPort.node = a
//        a!.inputPorts = [aInPort]
//        a!.outputPorts = [aOutPort]
//        
//        var bInPort = InputCompilerPort()
//        bInPort.node = b
//        var bOutPort = OutputCompilerPort()
//        bOutPort.node = b
//        b!.inputPorts = [bInPort]
//        b!.outputPorts = [bOutPort]
//        
//        var cInPort = InputCompilerPort()
//        cInPort.node = c
//        var cOutPort = OutputCompilerPort()
//        cOutPort.node = c
//        c!.inputPorts = [cInPort]
//        c!.outputPorts = [cOutPort]
//        
//        var dInPort = InputCompilerPort()
//        dInPort.node = d
//        var dOutPort = OutputCompilerPort()
//        dOutPort.node = d
//        d!.inputPorts = [dInPort]
//        d!.outputPorts = [dOutPort]
//        
//        var eInPort = InputCompilerPort()
//        eInPort.node = e
//        var eOutPort = OutputCompilerPort()
//        eOutPort.node = e
//        e!.inputPorts = [eInPort]
//        e!.outputPorts = [eOutPort]
//        
//        var fInPort = InputCompilerPort()
//        fInPort.node = f
//        var fOutPort = OutputCompilerPort()
//        fOutPort.node = f
//        f!.inputPorts = [fInPort]
//        f!.outputPorts = [fOutPort]
//        
//        var gInPort = InputCompilerPort()
//        gInPort.node = g
//        var gOutPort = OutputCompilerPort()
//        gOutPort.node = g
//        g!.inputPorts = [gInPort]
//        g!.outputPorts = [gOutPort]
//
//        let abEdge = CompilerEdge(inputPort: bInPort, outputPort: aOutPort)
//        let bIfConditionEdge = CompilerEdge(inputPort: condInputPort, outputPort: bOutPort)
//        let cdEdge = CompilerEdge(inputPort: dInPort, outputPort: cOutPort)
//        let dIfTrueEdge = CompilerEdge(inputPort: ifTrueInputPort, outputPort: dOutPort)
//        let eFalseEdge = CompilerEdge(inputPort: ifFalseInputPort, outputPort: eOutPort)
//        let ifFEdge = CompilerEdge(inputPort: fInPort, outputPort: ifElseOutputPort)
//        let fgEdge = CompilerEdge(inputPort: gInPort, outputPort: fOutPort)
//        let gOutEdge = CompilerEdge(inputPort: outputInPort, outputPort: gOutPort)
//        
//        eOutPort.dataType = .float2
//        
//        let nodes: [CompilerNode] = [a!, b!, c!, d!, e!, f!, g!, outputNode!, ifElseNode!]
//        graph.nodes = nodes
//        input = JelloCompilerInput(output: output, graph: graph)
//
//    }
//
//    
//    func testThatConcretisingTypesProducesExpectedResult() throws {
//        labelBranches(input: input!)
//        pruneGraph(input: input!)
//        topologicallyOrderGraph(input: input!)
//        try concretiseTypesInGraph(input: input!)
//        XCTAssertEqual(b!.outputPorts.map({$0.concreteDataType}), [JelloConcreteDataType.bool])
//        XCTAssertEqual(d!.outputPorts.map({$0.concreteDataType}), [JelloConcreteDataType.float2])
//        XCTAssertEqual(e!.outputPorts.map({$0.concreteDataType}), [JelloConcreteDataType.float2])
//        XCTAssertEqual(f!.inputPorts.map({$0.concreteDataType}), [JelloConcreteDataType.float2])
//        XCTAssertEqual(ifElseNode!.outputPorts.map({$0.concreteDataType}), [JelloConcreteDataType.float2])
//    }
//}
//
//
//final class JelloDecomposeGraphTest: XCTestCase {
//    var input: JelloCompilerInput? = nil
//    var common: GenericTestNode? = nil
//    var a: GenericTestNode? = nil
//    var b: GenericTestNode? = nil
//    var c: GenericTestNode? = nil
//    var d: GenericTestNode? = nil
//    var e: GenericTestNode? = nil
//    var f: GenericTestNode? = nil
//    var g: GenericTestNode? = nil
//    var outputNode: PreviewOutputCompilerNode? = nil
//    var ifElseNode: IfElseCompilerNode? = nil
//    var lonely1: GenericTestNode? = nil
//    var lonely2: GenericTestNode? = nil
//    
//    override func setUpWithError() throws {
//        var graph = CompilerGraph()
//        var outputInPort = InputCompilerPort()
//        outputNode = PreviewOutputCompilerNode(id: UUID(), inputPort: outputInPort)
//        let output = JelloCompilerInput.Output.previewOutput(outputNode!)
//
//        
//        outputInPort.node = outputNode
//        outputNode!.inputPorts = [outputInPort]
//        
//        a = GenericTestNode()
//        b = GenericTestNode()
//        c = GenericTestNode()
//        d = GenericTestNode()
//        e = GenericTestNode()
//        f = GenericTestNode()
//        g = GenericTestNode()
//        common = GenericTestNode()
//        lonely1 = GenericTestNode()
//        lonely2 = GenericTestNode()
//        
//        var condInputPort = InputCompilerPort()
//        var ifTrueInputPort = InputCompilerPort()
//        var ifFalseInputPort = InputCompilerPort()
//        var ifElseOutputPort = OutputCompilerPort()
//        ifElseNode = IfElseCompilerNode(id: UUID(), condition: condInputPort, ifTrue: ifTrueInputPort, ifFalse: ifFalseInputPort, outputPort: ifElseOutputPort)
//        condInputPort.node = ifElseNode
//        ifTrueInputPort.node = ifElseNode
//        ifFalseInputPort.node = ifElseNode
//        ifElseOutputPort.node = ifElseNode
//       
//        
//        var commonInPort1 = InputCompilerPort()
//        var commonInPort2 = InputCompilerPort()
//        commonInPort1.node = common
//        commonInPort2.node = common
//        var commonOutPort = OutputCompilerPort()
//        commonOutPort.node = common
//        common!.inputPorts = [commonInPort1, commonInPort2]
//        common!.outputPorts = [commonOutPort]
//        
//        var aInPort = InputCompilerPort()
//        aInPort.node = a
//        var aOutPort = OutputCompilerPort()
//        aOutPort.node = a
//        a!.inputPorts = [aInPort]
//        a!.outputPorts = [aOutPort]
//        
//        var bInPort = InputCompilerPort()
//        bInPort.node = b
//        var bOutPort = OutputCompilerPort()
//        bOutPort.node = b
//        b!.inputPorts = [bInPort]
//        b!.outputPorts = [bOutPort]
//        
//        var cInPort = InputCompilerPort()
//        cInPort.node = c
//        var cOutPort = OutputCompilerPort()
//        cOutPort.node = c
//        c!.inputPorts = [cInPort]
//        c!.outputPorts = [cOutPort]
//        
//        var dInPort = InputCompilerPort()
//        dInPort.node = d
//        var dOutPort = OutputCompilerPort()
//        dOutPort.node = d
//        d!.inputPorts = [dInPort]
//        d!.outputPorts = [dOutPort]
//        
//        var eInPort = InputCompilerPort()
//        eInPort.node = e
//        var eOutPort = OutputCompilerPort()
//        eOutPort.node = e
//        e!.inputPorts = [eInPort]
//        e!.outputPorts = [eOutPort]
//        
//        var fInPort = InputCompilerPort()
//        fInPort.node = f
//        var fOutPort = OutputCompilerPort()
//        fOutPort.node = f
//        f!.inputPorts = [fInPort]
//        f!.outputPorts = [fOutPort]
//        
//        var gInPort = InputCompilerPort()
//        gInPort.node = g
//        var gOutPort = OutputCompilerPort()
//        gOutPort.node = g
//        g!.inputPorts = [gInPort]
//        g!.outputPorts = [gOutPort]
//        
//        var lonely1InPort = InputCompilerPort()
//        lonely1InPort.node = lonely1
//        var lonely1OutPort = OutputCompilerPort()
//        lonely1OutPort.node = lonely1
//        lonely1!.inputPorts = [lonely1InPort]
//        lonely1!.outputPorts = [lonely1OutPort]
//        
//        var lonely2InPort = InputCompilerPort()
//        lonely2InPort.node = lonely2
//        var lonely2OutPort = OutputCompilerPort()
//        lonely2OutPort.node = lonely2
//        lonely2!.inputPorts = [lonely2InPort]
//        lonely2!.outputPorts = [lonely2OutPort]
//        
//        var nodes: [CompilerNode] = [a!, b!, c!, d!, e!, f!, g!, outputNode!, ifElseNode!, common!, lonely1!, lonely2!]
//        graph.nodes = nodes
//        
//        
//        // Finally connect up the graph
//        let aCommonEdge = CompilerEdge(inputPort: commonInPort1, outputPort: aOutPort)
//        let faEdge = CompilerEdge(inputPort: aInPort, outputPort: fOutPort)
//        let feEdge = CompilerEdge(inputPort: fInPort, outputPort: eOutPort)
//        let geEdge = CompilerEdge(inputPort: eInPort, outputPort: gOutPort)
//        let ebEdge = CompilerEdge(inputPort: bInPort, outputPort: eOutPort)
//        let bTrueEdge = CompilerEdge(inputPort: ifTrueInputPort, outputPort: bOutPort)
//        let cFalseEdge = CompilerEdge(inputPort: ifFalseInputPort, outputPort: cOutPort)
//        let dcEdge = CompilerEdge(inputPort: cInPort, outputPort: dOutPort)
//        let ifCommonEdge = CompilerEdge(inputPort: commonInPort2, outputPort: ifElseOutputPort)
//        let commonOutEdge = CompilerEdge(inputPort: outputInPort, outputPort: commonOutPort)
//        let lonely1lonely2Edge = CompilerEdge(inputPort: lonely2InPort, outputPort: lonely1OutPort)
//        let eLonely1Edge = CompilerEdge(inputPort: lonely1InPort, outputPort: eOutPort)
//        
//        input = JelloCompilerInput(output: output, graph: graph)
//    }
//
//    override func tearDownWithError() throws {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }
//    
//    func testThatDecomposingGraphProducesExpectedResult() throws {
//        labelBranches(input: input!)
//        pruneGraph(input: input!)
//        topologicallyOrderGraph(input: input!)
//        try concretiseTypesInGraph(input: input!)
//        decomposeBranches(input: input!)
//        let trueBranchId = ifElseNode!.trueBranchTag
//        let falseBranchId = ifElseNode!.falseBranchTag
//        let trueBranchNodes = ifElseNode!.subNodes[trueBranchId]!
//        let falseBranchNodes = ifElseNode!.subNodes[falseBranchId]!
//        
//        XCTAssertEqual(trueBranchNodes.map({$0.id}), [b!.id])
//        XCTAssertEqual(falseBranchNodes.map({$0.id}), [d!.id, c!.id])
//    }
//}
//
