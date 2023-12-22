//
//  JelloGraphProcessingTests.swift
//  JelloTests
//
//  Created by Natalie Cuthbert on 2023/12/22.
//

import Foundation
import XCTest
import JelloCompiler

class GenericNode : Node {
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
}

final class JelloLabelBranchesTest: XCTestCase {
    var input: JelloCompilerInput? = nil
    
    override func setUpWithError() throws {
        var graph = Graph()
        var outputNode = PreviewOutput()
        var output = JelloCompilerInput.Output.previewOutput(outputNode)
        input = JelloCompilerInput(output: output, graph: graph)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
}

final class JelloPruneGraphTest: XCTestCase {
    override func setUpWithError() throws {
       
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
}

final class JelloTopologicallyOrderGraphTest: XCTestCase {
    override func setUpWithError() throws {
       
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

}

final class JelloDecomposeGraphTest: XCTestCase {
    override func setUpWithError() throws {
       
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
}


