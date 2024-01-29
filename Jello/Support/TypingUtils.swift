import SwiftUI
import JelloCompilerStatic
import DequeModule
import SwiftData

extension JelloNodeCategory {
    func getCategoryGradient() -> Gradient {
        switch self {
        case .math:
            return Gradient(colors: [.green, .blue])
        case .other:
            return Gradient(colors: [.yellow, .orange])
        case .utility:
            return Gradient(colors: [.blue, .orange])
        case .material:
            return Gradient(colors: [.blue, .purple])
        case .value:
            return Gradient(colors: [.red, .purple])
        }
    }
}

extension JelloGraphDataType {
    func getTypeGradient() -> Gradient {
        switch self {
        case .bool:
            return Gradient(colors: [.purple, .teal])
        case .int:
            return Gradient(colors: [.red, .teal])
        case .float:
            return Gradient(colors: [.orange, .green])
        case .float2:
            return Gradient(colors: [.yellow, .green])
        case .float3:
            return Gradient(colors: [.red, .green])
        case .float4:
            return Gradient(colors: [.purple, .green])
        case .texture1d:
            return Gradient(colors: [.gray, .mint])
        case .texture2d:
            return Gradient(colors: [.cyan, .mint])
        case .texture3d:
            return Gradient(colors: [.indigo, .mint])
        case .any:
            return Gradient(colors: [.red, .yellow, .green, .blue])
        case .anyFloat:
            return Gradient(colors: [.green, .teal])
        case .anyTexture:
            return Gradient(colors: [.mint, .teal])
        case .anyMaterial:
            return Gradient(colors: [.blue, .purple])
        case .slabMaterial:
            return Gradient(colors: [.blue, .yellow])
        }
    }
    
    
    static func isPortTypeCompatible(edge: JelloGraphDataType, port: JelloGraphDataType) -> Bool {
        switch (edge, port) {
        case (_, .any):
            return true
        case (.any, _):
            return true
        case (let x, let y) where x == y:
            return true
        case (.float, .anyFloat):
            return true
        case (.float2, .anyFloat):
            return true
        case (.float3, .anyFloat):
            return true
        case (.float4, .anyFloat):
            return true
        case (.anyFloat, .float):
            return true
        case (.anyFloat, .float2):
            return true
        case (.anyFloat, .float3):
            return true
        case (.anyFloat, .float4):
            return true
        case (_, .anyFloat):
            return false
        case (.anyFloat, _):
            return false
        case (.texture1d, .anyTexture):
            return true
        case (.texture2d, .anyTexture):
            return true
        case (.texture3d, .anyTexture):
            return true
        case (.anyTexture, .texture1d):
            return true
        case (.anyTexture, .texture2d):
            return true
        case (.anyTexture, .texture3d):
            return true
        case (_, .anyTexture):
            return false
        case (.anyTexture, _):
            return false
        case (.anyMaterial, .slabMaterial):
            return true
        case (.slabMaterial, .anyMaterial):
            return true
        case (.anyMaterial, _):
            return false
        case (_, _):
            return false
        }
    }
    
    static func getMostSpecificType(a: JelloGraphDataType, b: JelloGraphDataType) -> JelloGraphDataType {
        switch (a, b) {
        case (let x, let y) where x == y:
            return x
        case (.any, let x):
            return x
        case (let x, .any):
            return x
        case (.anyFloat, let x):
            return x
        case (let x, .anyFloat):
            return x
        case (.anyTexture, let x):
            return x
        case (let x, .anyTexture):
            return x
        default:
            return a // Return first type as a tie breaker, both types are equally specific, so we need to choose one
        }
    }
    
    
    public func getGenericDomain() -> [JelloGraphDataType] {
        switch self {
        case .any:
            return JelloGraphDataType.allCases
        case .anyFloat:
            return [.anyFloat, .float, .float2, .float3, .float4]
        case .anyMaterial:
            return [.anyMaterial, .slabMaterial]
        case .anyTexture:
            return [.anyTexture, .texture1d, .texture2d, .texture3d]
        case .float:
            return [.float]
        case .float2:
            return [.float2]
        case .float3:
            return [.float3]
        case .float4:
            return [.float4]
        case .texture1d:
            return [.texture1d]
        case .texture2d:
            return [.texture2d]
        case .texture3d:
            return [.texture3d]
        case .int:
            return [.int]
        case .bool:
            return [.bool]
        case .slabMaterial:
            return [.slabMaterial]
        }
    }
}



enum CouldNotResolveTypesError: Error {
    case couldNotResolveTypesError
}

fileprivate func propagateConstraintsFromCurrentPort(port start: UUID, assignments: inout [UUID: JelloGraphDataType], domains: [UUID: [JelloGraphDataType]], constraints: [UUID:[PortConstraint]]) -> Bool {
    var queue = Deque<UUID>([start])
    var type: JelloGraphDataType = assignments[start]!
    while !queue.isEmpty {
        let currentPort = queue.popFirst()!
        let constraintsForCurrentPort = constraints[currentPort] ?? []
        type = assignments[currentPort]!
        for constraint in constraintsForCurrentPort {
            switch constraint.apply(assignments: &assignments, domains: domains, port: currentPort, type: type) {
            case .contradiction:
                return false
            case .dirty(let dirtyPorts):
                queue.append(contentsOf: dirtyPorts)
                break
            case .unchanged:
                break
            }
        }
    }
    return true
}

fileprivate func resolveTypesInGraphImpl(remainingPorts: ArraySlice<UUID>, domains: [UUID: [JelloGraphDataType]], assignments: [UUID: JelloGraphDataType], constraints: [UUID:[PortConstraint]]) -> [UUID: JelloGraphDataType]? {
    if remainingPorts.count == 0 {
        return assignments
    }
        
    let currentPort = remainingPorts.first!
    guard let domain = domains[currentPort] else {
        return nil
    }
    
    if assignments[currentPort] != nil {
        let nextRemainingPorts = remainingPorts.dropFirst()
        var nextAssignments = assignments
        if !propagateConstraintsFromCurrentPort(port: currentPort, assignments: &nextAssignments, domains: domains, constraints: constraints) {
            return nil
        }
        if let result = resolveTypesInGraphImpl(remainingPorts: nextRemainingPorts, domains: domains, assignments: assignments, constraints: constraints) {
            return result
        }
        return nil
    }
    
    for value in domain {
        var nextAssignments = assignments
        nextAssignments[currentPort] = value
        if !propagateConstraintsFromCurrentPort(port: currentPort, assignments: &nextAssignments, domains: domains, constraints: constraints) {
            continue
        }
        let nextRemainingPorts = remainingPorts.dropFirst()
        if let result = resolveTypesInGraphImpl(remainingPorts: nextRemainingPorts, domains: domains, assignments: nextAssignments, constraints: constraints) {
            return result
        }
    }
    
    return nil
}

fileprivate func resolveTypesInGraph(graph: CompilerGraph) throws -> [UUID: JelloGraphDataType] {
    let inputPorts = graph.nodes.flatMap({$0.inputPorts})
    let outputPorts = graph.nodes.flatMap({$0.outputPorts})
    
    var domains : [UUID: [JelloGraphDataType]] = [:]
    for port in inputPorts {
        domains[port.id] = port.dataType.getGenericDomain()
    }
    for port in outputPorts {
        domains[port.id] = port.dataType.getGenericDomain()
    }

    // Create a topologically ordered set of ports
    var ports: [UUID] = []
    for node in graph.nodes {
        ports.append(contentsOf: node.inputPorts.map({$0.id}))
        ports.append(contentsOf: node.outputPorts.map({$0.id}))
    }
    
    var assignments: [UUID: JelloGraphDataType] = [:]
    
  
    // Set up constraints
    var constraints: [PortConstraint] = []
    
    // Edge constraints
    
    let edges = inputPorts.filter({$0.incomingEdge != nil}).map({$0.incomingEdge!})
    for edge in edges {
        constraints.append(SameTypesConstraint(ports: [edge.inputPort.id, edge.outputPort.id]))
    }
    
    // Node constraints
    for node in graph.nodes {
        constraints.append(contentsOf: node.constraints)
    }
    
    // Create a lookup so that we can conveniently find the set of constraints for a given node
    var constraintsMapped: [UUID: [PortConstraint]] = [:]
    for constraint in constraints {
        for constraintPort in constraint.ports {
            var constrainForPort = constraintsMapped[constraintPort] ?? []
            constrainForPort.append(constraint)
            constraintsMapped[constraintPort] = constrainForPort
        }
    }
    
    // Optimization. Assign types that only have one value in the domain first
    for port in ports {
        if let d = domains[port], d.count == 1, let type = d.first {
            assignments[port] = type
            if !propagateConstraintsFromCurrentPort(port: port, assignments: &assignments, domains: domains, constraints: constraintsMapped) {
                throw CouldNotResolveTypesError.couldNotResolveTypesError // We cannot unify this graph, as these constraints *have* to hold
            }
        }
    }
    
    
    guard let result: [UUID: JelloGraphDataType] = resolveTypesInGraphImpl(remainingPorts: ArraySlice(ports), domains: domains, assignments: assignments, constraints: constraintsMapped) else {
        throw CouldNotResolveTypesError.couldNotResolveTypesError
    }
    
    return result
}


func updateTypesInGraph(modelContext: ModelContext, graphId: UUID) throws {
    try modelContext.transaction {
        let graphs = try modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloGraph> { $0.uuid == graphId }))
        let nodes = try modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloNode> { $0.graph?.uuid == graphId }))
        let edges = try modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloEdge> { $0.graph?.uuid == graphId }))
        let nodeData = try modelContext.fetch(FetchDescriptor<JelloNodeData>()).filter({$0.node?.graph?.uuid == graphId})
        let inputPorts = (try modelContext.fetch(FetchDescriptor<JelloInputPort>())).filter({$0.node?.graph?.uuid == graphId})
        let outputPorts = try modelContext.fetch(FetchDescriptor<JelloOutputPort>()).filter({$0.node?.graph?.uuid == graphId})
        
        let graphInput = JelloCompilerService.buildGraph(jelloGraph: graphs.first!, jelloNodes: nodes, jelloNodeData: nodeData, jelloEdges: edges, jelloInputPorts: inputPorts, jelloOutputPorts: outputPorts, useBaseDataTypes: true)
        
        let assignments = try resolveTypesInGraph(graph: graphInput)
        
        var changedInputPorts: [UUID: (JelloGraphDataType, JelloInputPort)] = [:]
        var changedOutputPorts: [UUID: (JelloGraphDataType, JelloOutputPort)] = [:]
        
        for inputPort in inputPorts {
            if let assignment = assignments[inputPort.uuid] {
                if inputPort.currentDataType != assignment {
                    changedInputPorts[inputPort.uuid] = (inputPort.currentDataType, inputPort)
                    inputPort.currentDataType = assignment
                }
            }
        }
    
        for outputPort in outputPorts {
            if let assignment = assignments[outputPort.uuid] {
                if outputPort.currentDataType != assignment {
                    changedOutputPorts[outputPort.uuid] = (outputPort.currentDataType, outputPort)
                    outputPort.currentDataType = assignment
                }
            }
        }
        
        for edge in edges {
            if let inputPortType = edge.inputPort?.currentDataType, let outputPortType = edge.outputPort?.currentDataType {
                edge.dataType = JelloGraphDataType.getMostSpecificType(a: inputPortType, b: outputPortType)
            }
        }
        
        for key in changedInputPorts.keys {
            let (prevType, inputPort) = changedInputPorts[key]!
            if let node = inputPort.node {
                let controller = JelloNodeControllerFactory.getController(node)
                controller.onInputPortTypeChanged(port: inputPort, prevType: prevType)
            }
        }
        
        for key in changedOutputPorts.keys {
            let (prevType, outputPort) = changedOutputPorts[key]!
            if let node = outputPort.node {
                let controller = JelloNodeControllerFactory.getController(node)
                controller.onOutputPortTypeChanged(port: outputPort, prevType: prevType)
            }
        }
    }
    
}
