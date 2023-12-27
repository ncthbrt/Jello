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
        let spirvFile = try compileToSpirv(input: input!)
        print(spirvFile)
        let result = try compileMSLShader(spirv: spirvFile)
        let expectedResult = """
#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

vertex void main0()
{
}


"""
        XCTAssertEqual(result, expectedResult)
        
    }
}
