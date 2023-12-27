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
        let vertexResult = try compileMSLShader(spirv: vertexSpirv)
        let fragmentResult = try compileMSLShader(spirv: fragmentSpirv)
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
        
        let expectedVertexResult = """
#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

vertex void vertexMain()
{
}


"""
        XCTAssertEqual(fragmentResult, expectedFragmentResult)
        XCTAssertEqual(vertexResult, expectedVertexResult)
    }
}
