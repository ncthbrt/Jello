//
//  JelloCompilerTests.swift
//  JelloCompilerTests
//
//  Created by Natalie Cuthbert on 2023/12/27.
//

import Foundation
@testable import JelloCompilerStatic
import XCTest
import simd

final class JelloIfElseBranchesTest: XCTestCase {
    var input: JelloCompilerInput? = nil
    
    override func setUpWithError() throws {
        var graph = CompilerGraph()
        var outputInPort = InputCompilerPort()
        var outputNode = PreviewOutputCompilerNode(id: UUID(), inputPort: outputInPort)
        var output: JelloCompilerInput.Output = .previewOutput(outputNode)
        outputInPort.node = outputNode
        
        var condInputPort = InputCompilerPort()
        var ifTrueInputPort = InputCompilerPort()
        var ifFalseInputPort = InputCompilerPort()
        var ifElseOutputPort = OutputCompilerPort()
        var ifElseNode = IfElseCompilerNode(id: UUID(), condition: condInputPort, ifTrue: ifTrueInputPort, ifFalse: ifFalseInputPort, outputPort: ifElseOutputPort)
        condInputPort.node = ifElseNode
        ifTrueInputPort.node = ifElseNode
        ifFalseInputPort.node = ifElseNode
        ifElseOutputPort.node = ifElseNode
        
        var trueValueNode = ConstantCompilerNode(outputPort: OutputCompilerPort(), value: .float4(vector_float4(1, 0, 0, 1)))
        var falseValueNode = ConstantCompilerNode(outputPort: OutputCompilerPort(), value: .float4(vector_float4(0, 0, 1, 1)))
        trueValueNode.outputPorts.first!.node = trueValueNode
        falseValueNode.outputPorts.first!.node = falseValueNode
        
        var trueCondNode = ConstantCompilerNode(outputPort: OutputCompilerPort(), value: .bool(true))
        trueCondNode.outputPorts.first!.node = trueCondNode
    
        var nodes: [CompilerNode] = [outputNode, ifElseNode, trueValueNode, falseValueNode, trueCondNode]
        graph.nodes = nodes
        
        // Finally connect up the graph
        let condIfElseEdge = CompilerEdge(inputPort: condInputPort, outputPort: trueCondNode.outputPorts.first!)
        let trueIfElseEdge = CompilerEdge(inputPort: ifTrueInputPort, outputPort: trueValueNode.outputPorts.first!)
        let falseIfElseEdge = CompilerEdge(inputPort: ifFalseInputPort, outputPort: falseValueNode.outputPorts.first!)
        let ifElsePreviewEdge = CompilerEdge(inputPort: outputInPort, outputPort: ifElseOutputPort)
        
        input = JelloCompilerInput(output: output, graph: graph)
    }

    
    public func testThatCompilingGraphProducesExpectedResult() throws {
        let (vertex:vertexSpirv, fragment: fragmentSpirv) = try compileToSpirv(input: input!)
        XCTAssertNotNil(fragmentSpirv)
        XCTAssertNil(vertexSpirv)

        guard let someSpirv = fragmentSpirv else {
            return
        }
        let fragmentResult = try compileMSLShader(spirv: someSpirv)
        let expectedFragmentResult = """
#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct fragmentMain_out
{
    float4 frag_out [[color(0)]];
};

fragment fragmentMain_out fragmentMain()
{
    fragmentMain_out out = {};
    float4 _24;
    if (true)
    {
        _24 = float4(1.0, 0.0, 0.0, 1.0);
    }
    else
    {
        _24 = float4(0.0, 0.0, 1.0, 1.0);
    }
    out.frag_out = _24;
    return out;
}


"""
        XCTAssertEqual(fragmentResult, expectedFragmentResult)
    }
}


final class JelloAddTest: XCTestCase {
    var input: JelloCompilerInput? = nil
    
    override func setUpWithError() throws {
        var graph = CompilerGraph()
        var outputInPort = InputCompilerPort()
        var outputNode = PreviewOutputCompilerNode(id: UUID(), inputPort: outputInPort)
        var output: JelloCompilerInput.Output = .previewOutput(outputNode)
        outputInPort.node = outputNode
        
        var i1 = InputCompilerPort()
        var i2 = InputCompilerPort()
        var i3 = InputCompilerPort()
        var o1 = OutputCompilerPort()
        var node = AddCompilerNode(inputPorts: [i1, i2, i3], outputPort: o1)
        var i1Node = ConstantCompilerNode(outputPort: OutputCompilerPort(), value: .float4(vector_float4(1, 0, 0, 1)))
        var i2Node = ConstantCompilerNode(outputPort: OutputCompilerPort(), value: .float4(vector_float4(0, 1, 0, 0)))
        var i3Node = ConstantCompilerNode(outputPort: OutputCompilerPort(), value: .float4(vector_float4(0, 0, 1, 0)))
        
        
        var nodes: [CompilerNode] = [outputNode, node, i1Node, i2Node, i3Node]
        graph.nodes = nodes
        
        // Finally connect up the graph
        let i1Edge = CompilerEdge(inputPort: i1, outputPort: i1Node.outputPorts.first!)
        let i2Edge = CompilerEdge(inputPort: i2, outputPort: i2Node.outputPorts.first!)
        let i3Edge = CompilerEdge(inputPort: i3, outputPort: i3Node.outputPorts.first!)
        let outPreviewEdge = CompilerEdge(inputPort: outputInPort, outputPort: o1)

        input = JelloCompilerInput(output: output, graph: graph)
    }

    
    public func testThatCompilingGraphProducesExpectedResult() throws {
        let (vertex:vertexSpirv, fragment: fragmentSpirv) = try compileToSpirv(input: input!)
        XCTAssertNotNil(fragmentSpirv)
        XCTAssertNil(vertexSpirv)
        print(fragmentSpirv)
        guard let someSpirv = fragmentSpirv else {
            return
        }
        let fragmentResult = try compileMSLShader(spirv: someSpirv)
        let expectedFragmentResult = """
#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct fragmentMain_out
{
    float4 frag_out [[color(0)]];
};

fragment fragmentMain_out fragmentMain()
{
    fragmentMain_out out = {};
    out.frag_out = (float4(1.0, 0.0, 0.0, 1.0) + float4(0.0, 1.0, 0.0, 0.0)) + float4(0.0, 0.0, 1.0, 0.0);
    return out;
}


"""
        
        XCTAssertEqual(fragmentResult, expectedFragmentResult)
    }
}
