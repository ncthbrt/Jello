//
//  JelloNodeBaker.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/02/19.
//

import Foundation
import SwiftUI
import SwiftData
import JelloCompilerStatic
import CryptoKit
import Metal
import MetalKit
import simd




@ModelActor
actor JelloPreviewBakerActor {
    private var device: MTLDevice?
    private var metalKitTextureLoader: MTKTextureLoader? = nil
    private var modelIOVertexDescriptor: MDLVertexDescriptor? = nil
    private var vertexDescriptor: MTLVertexDescriptor? = nil
    private struct ShaderKey : Hashable {
        let stageId: UUID
        let index: UInt32
    }
    
    private var shaderLibs: [ShaderKey: MTLLibrary] = [:]
    private var compiledSpirv: [ShaderKey: MslSpirvShaderOutput] = [:]
    private var previewGeometry: [JelloPreviewGeometry: [JelloMesh]] = [:]
    

    
    private func calculateWedgeSha256(encoder: PropertyListEncoder, geometry: JelloPreviewGeometry?) -> Data {
        if let geo = geometry {
            return (try! encoder.encode(geo).sha256())
        }
        return Data()
    }
    
    private func initializeSharedResources() {
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported")
        }
        
        assert(defaultDevice.supportsFamily(.apple4),
               "Application requires MTLGPUFamilyApple4 (only available on Macs with Apple Silicon or iOS devices with an A11 or later)")
        
        device = defaultDevice
        
        metalKitTextureLoader = MTKTextureLoader(device: defaultDevice)
        
        self.vertexDescriptor = MTLVertexDescriptor()
        // Positions.
        vertexDescriptor!.attributes[0].format = .float3
        vertexDescriptor!.attributes[0].offset = 0
        vertexDescriptor!.attributes[0].bufferIndex = 0

        // Texture coordinates.
        vertexDescriptor!.attributes[1].format = .float2
        vertexDescriptor!.attributes[1].offset = 16
        vertexDescriptor!.attributes[1].bufferIndex = 0

        // Normals.
        vertexDescriptor!.attributes[2].format = .float3
        vertexDescriptor!.attributes[2].offset = 32
        vertexDescriptor!.attributes[2].bufferIndex = 0

        // Tangents.
        vertexDescriptor!.attributes[3].format = .float3
        vertexDescriptor!.attributes[3].offset = 48
        vertexDescriptor!.attributes[3].bufferIndex = 0

        // Bitangents.
        vertexDescriptor!.attributes[4].format = .float3
        vertexDescriptor!.attributes[4].offset = 64
        vertexDescriptor!.attributes[4].bufferIndex = 0

        // Generic attribute buffer layout.
        vertexDescriptor!.layouts[0].stride = 80

        modelIOVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(vertexDescriptor!)
    }
    
    private func loadTexture(textureUsage: MTLTextureUsage, storageMode: MTLStorageMode, texture: Data) throws -> MTLTexture {
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [
            .textureUsage: textureUsage.rawValue,
            .textureStorageMode: storageMode.rawValue,
        ]

        return try metalKitTextureLoader!.newTexture(data: texture, options: textureLoaderOptions)
    }

    private func bindGeometry(geometry: JelloPreviewGeometry, argumentEncoder: inout MTLArgumentEncoder, indicesBinding: UInt32, verticesBinding: UInt32) throws {
        let g = if let geo = self.previewGeometry[geometry] {
            geo
        } else {
            try loadPreviewGeometry(geometry, modelIOVertexDescriptor: modelIOVertexDescriptor!, device: device!)
        }
        previewGeometry[geometry] = g
        // We assume that preview geometry only has a single mesh and submesh
        let mesh0 = g[0]
        let subMesh0 = mesh0.submeshes[0]
        let indicesBuffer = subMesh0.metalKitSubmesh.indexBuffer
        let verticesBuffer = mesh0.metalKitMesh.vertexBuffers[0]
        
        
        argumentEncoder.setBuffer(verticesBuffer.buffer, offset: verticesBuffer.offset, index:  Int(verticesBinding))
        argumentEncoder.setBuffer(indicesBuffer.buffer, offset: indicesBuffer.offset, index: Int(indicesBinding))
    }
    
    private func renderCompute(stageId: UUID, stageIndex: UInt32, geometry: JelloPreviewGeometry?, shader: SpirvShader, computeTextureResources: Set<UUID>) throws -> Data {
        if device == nil {
            initializeSharedResources()
        }
        
        // TODO: Cache textures if a dependency of timeVarying or transform dependant functions
        var textures: [(JelloPersistedTextureResource, MTLTexture)] = []
        for resource in computeTextureResources {
            let id = resource
            if let texture = (try modelContext.fetch(FetchDescriptor<JelloPersistedTextureResource>(predicate: #Predicate { $0.uuid == id }), batchSize: 1)).first {
                textures.append(((texture,try loadTexture(textureUsage: [.shaderRead], storageMode: .private, texture: texture.texture ?? Data()))))
            }
        }
        
        let key = ShaderKey(stageId: stageId, index: stageIndex)
        let msl: MslSpirvShaderOutput = try compiledSpirv[key] ?? compileMSLShader(input: shader)
        compiledSpirv[key] = msl
        let maybeShaderLib = shaderLibs[key]
        
        let shaderLib = if let shaderLib = maybeShaderLib {
            shaderLib
        } else {
            switch msl {
            case .compute(let c):
                try device!.makeLibrary(source: c.shader, options: MTLCompileOptions())
            case .computeRasterizer(let r):
                try device!.makeLibrary(source: r.shader, options: MTLCompileOptions())
            default:
                fatalError("Unexpected shader type")
            }
        }
        
        shaderLibs[key] = shaderLib
        let computeMain = shaderLib.makeFunction(name: "computeMain")
        var geometryArgumentEncoder = computeMain!.makeArgumentEncoder(bufferIndex: Int(geometryInputDescriptorSet))
        
        // Bind geometry and triangle index input texture
        switch msl {
        case .compute(let c):
            if let indicesBindingIndex = c.indicesBindingIndex,
               let verticesBindingIndex = c.verticesBindingIndex {
                try bindGeometry(geometry: geometry!, argumentEncoder: &geometryArgumentEncoder, indicesBinding: indicesBindingIndex, verticesBinding: verticesBindingIndex)
                let geometryTextures = c.inputComputeTextures.filter({$0.bufferIndex == geometryInputDescriptorSet })
                for geometryTexture in geometryTextures {
                    let t = textures.first(where: {$0.0.originatingPass == geometryTexture.texture.originatingPass && $0.0.originatingStage == geometryTexture.texture.originatingStage })
                    geometryArgumentEncoder.setTexture(t!.1, index: Int(geometryTexture.bufferBindingIndex))
                    assert(!geometryTexture.sampled, "Geometry Textures should never be sampled")
                }
            }
        case .computeRasterizer(let r):
            if let indicesBindingIndex = r.indicesBindingIndex,
               let verticesBindingIndex = r.verticesBindingIndex {
                try bindGeometry(geometry: geometry!, argumentEncoder: &geometryArgumentEncoder, indicesBinding: indicesBindingIndex, verticesBinding: verticesBindingIndex)
           
            }
        default:
            fatalError("Unexpected shader type")
        }
        
        func makeOutputTexture(texDefn: MslSpirvTextureBindingOutput) throws -> MTLTexture {
            let textureDescriptor = MTLTextureDescriptor()
            textureDescriptor.pixelFormat = switch texDefn.texture.format {
            case .R32f:
                    .r32Float
            case .R32i:
                    .r32Sint
            case .Rgba32f:
                    .rgba32Float
            case .Rgba16f:
                    .rgba16Float
            }
            
            guard case .dimension(let x, let y, let z) = texDefn.texture.size else {
                fatalError("No dimension")
            }
            textureDescriptor.width = x;
            textureDescriptor.height = y;
            textureDescriptor.depth = z
            
            textureDescriptor.textureType = z > 1 ? .type3D : (y > 1 ? .type2D : .type1D)
            
            // The image kernel only needs to read the incoming image data.
            
            textureDescriptor.usage = [.shaderWrite, .shaderRead];
            textureDescriptor.storageMode = .shared

            return device!.makeTexture(descriptor: textureDescriptor)!
        }
        
        let computeTextureInputOutputEncoder = computeMain!.makeArgumentEncoder(bufferIndex: Int(computeTextureInputOutputDescriptorSet))
        
        let outputTexture: MTLTexture = switch msl {
        case .compute(let c):
            try makeOutputTexture(texDefn: c.outputComputeTexture)
        case .computeRasterizer(let r):
            try makeOutputTexture(texDefn: r.outputComputeTexture)
        default:
            fatalError("Unexpected shader type")
        }
        
        switch msl {
        case .compute(let c):
                let computeTextureInputs = c.inputComputeTextures.filter({$0.bufferIndex == computeTextureInputOutputDescriptorSet })
                for computeTextureInput in computeTextureInputs {
                    let t = textures.first(where: {$0.0.originatingPass == computeTextureInput.texture.originatingPass && $0.0.originatingStage == computeTextureInput.texture.originatingStage })
                    computeTextureInputOutputEncoder.setTexture(t!.1, index: Int(computeTextureInput.bufferBindingIndex))
                    
                    if computeTextureInput.sampled {
                        let samplerDesc = MTLSamplerDescriptor();
                        samplerDesc.minFilter = .linear;
                        samplerDesc.magFilter = .linear;
                        samplerDesc.mipFilter = .notMipmapped;
                        samplerDesc.normalizedCoordinates = true;
                        samplerDesc.supportArgumentBuffers = true;

                        let sampler = device!.makeSamplerState(descriptor: samplerDesc)
                        // We assume that the sampler is bound to the next index as the texture
                        computeTextureInputOutputEncoder.setSamplerState(sampler, index: Int(computeTextureInput.bufferBindingIndex) + 1)
                    }
                }
            computeTextureInputOutputEncoder.setTexture(outputTexture, index: Int(c.outputComputeTexture.bufferBindingIndex))
        case .computeRasterizer(let r):
            computeTextureInputOutputEncoder.setTexture(outputTexture, index: Int(r.outputComputeTexture.bufferBindingIndex))
        default:
            break // Do nothing
        }
        
        let pipelineState: MTLComputePipelineState = try device!.makeComputePipelineState(function: computeMain!)
        
        
        let commandQueue: MTLCommandQueue = device!.makeCommandQueue()!
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        computeEncoder.setComputePipelineState(pipelineState)
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        return outputTexture.data
    }
    
    
    func compileAndDispatchComputeShaders(_ modelContainer: ModelContainer,  graphId: UUID) async throws {
        let graph = try modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloGraph>{ $0.uuid == graphId })).first!
        let nodes = try modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloNode>{ $0.graph?.uuid == graphId }))
        let edges = try modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloEdge>{ $0.graph?.uuid == graphId }))
        let data = try modelContext.fetch(FetchDescriptor<JelloNodeData>()).filter({$0.node?.graph?.uuid == graphId})
        let inputPorts = try modelContext.fetch(FetchDescriptor<JelloInputPort>(sortBy: [SortDescriptor(\JelloInputPort.index)])).filter({$0.node?.graph?.uuid == graphId})
        let outputPorts = try modelContext.fetch(FetchDescriptor<JelloOutputPort>(sortBy: [SortDescriptor(\JelloOutputPort.index)])).filter({$0.node?.graph?.uuid == graphId})
        let encoder = PropertyListEncoder()

        // TODO: Cater for material output node as well
        let previewNodes = nodes.filter({$0.nodeType == .builtIn(.preview)})
        var stages: Set<JelloCompilerOutputStage> = []
        var geometry: [UUID: Set<JelloPreviewGeometry>] = [:]
        for previewNode in previewNodes {
            let thisPreviewGeometry: JelloPreviewGeometry = .sphere
            let graphInput = JelloCompilerBridge.buildGraphInput(outputNode: previewNode, jelloGraph: graph, jelloNodes: nodes, jelloNodeData: data, jelloEdges: edges, jelloInputPorts: inputPorts, jelloOutputPorts: outputPorts)
            if let result = try? JelloCompilerStatic.compileToSpirv(input: graphInput) {
                stages.formUnion(result.stages)
                for stage in result.stages {
                    if stage.domain.contains(CompilerComputationDomain.modelDependant) || stage.domain.contains(CompilerComputationDomain.transformDependant)  {
                        if geometry[stage.id] == nil {
                            geometry[stage.id] = []
                        }
                        geometry[stage.id]!.insert(thisPreviewGeometry)
                    }
                }
            }
            try Task.checkCancellation()
        }
        
        
        var resourceIds: [UUID: [[Data: Set<UUID>]]] = [:]
        // Add JelloPersistedStageShader references to every stage
        for stage in stages {
            let stageId = stage.id
            resourceIds[stageId] = []
            for shaderIndex in stage.shaders.indices {
                let index = UInt32(shaderIndex)
                let persistedShaders = try modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloPersistedStageShader>{ $0.graphId == graphId && $0.stageId == stageId && $0.index == index }))
                var wedges: [Data] = []
                if let geometries = geometry[stageId] {
                    wedges = geometries.map({ self.calculateWedgeSha256(encoder: encoder, geometry: $0)})
                } else {
                    wedges = [Data()]
                }
                for wedgeSha256 in wedges {
                    var persistedShader = persistedShaders.first(where: { $0.wedgeSha256 == wedgeSha256 })
                    if persistedShader == nil {
                        persistedShader = JelloPersistedStageShader(graphId: graphId, stageId: stageId, index: index, wedgeSha256: wedgeSha256, shaderSha256: Data(), argsSha256: Data())
                        modelContext.insert(persistedShader!)
                    }
                    resourceIds[stageId]?.append([wedgeSha256: Set(persistedShader!.resources)])
                }
            }
        }
        
        // Clean up unused stages & wedges
        var persistedStages = try modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloPersistedStageShader>{ $0.graphId == graphId }))
        for persistedStageIndex in persistedStages.indices.reversed() {
            let persistedStage = persistedStages[persistedStageIndex]
            if resourceIds[persistedStage.stageId] == nil {
                modelContext.delete(persistedStage)
                persistedStages.remove(at: persistedStageIndex)
            } else if let geometry = geometry[persistedStage.stageId] {
                let wedgesSet =  Set<Data>(geometry.map({ self.calculateWedgeSha256(encoder: encoder, geometry: $0) }))
                if !wedgesSet.contains(persistedStage.wedgeSha256) {
                    modelContext.delete(persistedStage)
                    persistedStages.remove(at: persistedStageIndex)
                }
            } else if persistedStage.wedgeSha256 != Data() {
                modelContext.delete(persistedStage)
                persistedStages.remove(at: persistedStageIndex)
            }
        }

        
        let stagesDict: [UUID: JelloCompilerOutputStage] = stages.reduce(into: [:], { dict, stage in dict[stage.id] = stage })
    
        
        while true {
            var visitedStages: Set<UUID> = []
            func hasNoDependencies(stage: JelloCompilerOutputStage) -> Bool {
                return stage.dependencies.filter({ dependency in
                    return !visitedStages.contains(dependency)
                }).isEmpty
            }
            var noDependencyStages: [JelloCompilerOutputStage] = stages.filter({ hasNoDependencies(stage: $0) })
            var i = 0
            // TODO: Execute these in parallel
            while i < noDependencyStages.count {
                let item = noDependencyStages[i]
                visitedStages.insert(item.id)
                let stageId = item.id
                let persistedShaders = try modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloPersistedStageShader>{ $0.graphId == graphId && $0.stageId == stageId }))
                let isVertexFragStage = item.shaders.contains(where: {
                    switch $0 {
                    case .fragment(_), .vertex(_):
                        return true
                    default:
                        return false
                    }
                })
                func updateDependantShaderStagesAndFreeResources(renderResult: Data, persistedShader: JelloPersistedStageShader, shaderSha256: Data, argsSha256: Data) throws {
                    try modelContext.transaction {
                        persistedShader.argsSha256 = argsSha256
                        persistedShader.shaderSha256 = shaderSha256
                        let maybeOldId = persistedShader.output?.uuid
                        let texture = JelloPersistedTextureResource(uuid: UUID(), texture: renderResult, originatingStage: stageId, originatingPass: persistedShader.index, wedgeSha256: persistedShader.wedgeSha256)
                        modelContext.insert(texture)
                        persistedShader.output = texture
                        // Bind resource to successor stages
                        var possibleDependants = item.dependants
                        // Add self as a dependency for inter shader dependencies
                        possibleDependants.insert(stageId)
                        
                        for possibleDependant in possibleDependants {
                            if let stage = stagesDict[possibleDependant] {
                                for shaderIndex in stage.shaders.indices {
                                    let inputs = stage.shaders[shaderIndex].inputComputeTextures
                                    if inputs.contains(where: { $0.texture.originatingPass == persistedShader.index && $0.texture.originatingStage == stageId }) {
                                        let dependantIndex = UInt32(shaderIndex)
                                        let dependantStageId = possibleDependant
                                        let dependantShader = try modelContext.fetch(FetchDescriptor<JelloPersistedStageShader>(predicate: #Predicate { $0.index == dependantIndex && $0.stageId == dependantStageId })).first
                                        dependantShader?.resources.append(texture.uuid)
                                    }
                                }
                            }
                        }
                        // Unbind old resource from all stages
                        if let oldId = maybeOldId {
                            let oldOutput = try modelContext.fetch(FetchDescriptor<JelloPersistedTextureResource>(predicate: #Predicate { $0.uuid == oldId })).first
                            modelContext.delete(oldOutput!)
                            let dependantShaders = try modelContext.fetch(FetchDescriptor<JelloPersistedStageShader>(predicate: #Predicate { $0.graphId == graphId }))
                            for shader in dependantShaders {
                                shader.resources = shader.resources.filter({ $0 != oldId })
                            }
                        }
                    }
                }
                if isVertexFragStage {
                    if let geometries = geometry[item.id] {
                        for geometry in geometries {
                            let wedgeSha256 = calculateWedgeSha256(encoder: encoder, geometry: geometry)
                            let renderResult = Data()
                            let fragmentIndex = UInt32(item.shaders.firstIndex(where: {
                                switch $0 {
                                case .fragment(_):
                                    return true
                                default:
                                    return false
                                }
                            }) ?? 0)
                            let vertexIndex = UInt32(item.shaders.firstIndex(where: {
                                switch $0 {
                                case .vertex(_):
                                    return true
                                default:
                                    return false
                                }
                            }) ?? 0)
                            if let persistedShader = persistedShaders.first(where: { $0.index == fragmentIndex && $0.wedgeSha256 == wedgeSha256 }) {
                                // TODO: Insert Variable Args here
                                let argsSha256 = Data()
                                let shaderSha256 = item.shaders[Int(fragmentIndex)].shader.withUnsafeBufferPointer { Data(buffer: $0).sha256() }
                                try updateDependantShaderStagesAndFreeResources(renderResult: renderResult, persistedShader: persistedShader, shaderSha256: shaderSha256, argsSha256: argsSha256)
                            }
                            
                            if let persistedShader = persistedShaders.first(where: {  $0.index == vertexIndex && $0.wedgeSha256 == wedgeSha256 }) {
                                // TODO: Insert Variable Args here
                                let argsSha256 = Data()
                                let shaderSha256 = item.shaders[Int(vertexIndex)].shader.withUnsafeBufferPointer { Data(buffer: $0).sha256() }
                                try modelContext.transaction {
                                    persistedShader.argsSha256 = argsSha256
                                    persistedShader.shaderSha256 = shaderSha256
                                }
                            }
                        }
                    } else {
                        fatalError("Expected vert frag stages to always have associated preview geometry")
                    }
                } else {
                    for shaderIndex in item.shaders.indices {
                        let index = UInt32(shaderIndex)
                        let shader = item.shaders[shaderIndex]
                        let shaderSha256 = shader.shader.withUnsafeBufferPointer { Data(buffer: $0).sha256() }
                        var argsSha256 = Data()
                        let domain = shader.domain
                        // TODO: Insert Variable Args here
                        switch shader {
                        case .compute(let c):
                            argsSha256 = try encoder.encode(c.outputComputeTexture).sha256()
                        case .computeRasterizer(let r):
                            argsSha256 = try encoder.encode(r.outputComputeTexture).sha256()
                        default:
                            fatalError("Unexpected shader type")
                        }
//                        
                        let prevResources: [Data: Set<UUID>] = resourceIds[stageId]?[shaderIndex] ?? [:]
                        var wedges: [(Data, JelloPreviewGeometry?)] = []
//                        
                        if let previewGeometries = geometry[item.id] {
                            wedges = previewGeometries.map({ (calculateWedgeSha256(encoder: encoder, geometry: $0), $0) })
                        } else {
                            let wedgeSha256 = Data()
                            wedges.append((wedgeSha256, nil))
                        }
                        for wedgeAndGeometry in wedges {
                            let wedgeSha256 = wedgeAndGeometry.0
                            let geometry = wedgeAndGeometry.1
                            
                            if let persistedShader = persistedShaders.first(where: { $0.index == index && $0.wedgeSha256 == wedgeSha256 }) {
                                let currentResources = Set(persistedShader.resources)
                                func isDirty() -> Bool {
                                    let isTimeVaryingOrTransformDependant: Bool = !(domain.intersection([.timeVarying, .transformDependant]).isEmpty)
                                    let differentArgsOrShader: Bool = persistedShader.argsSha256 != argsSha256 || persistedShader.shaderSha256 != shaderSha256
                                    let differentResources: Bool = prevResources[wedgeSha256] != currentResources
                                    let dirty: Bool = isTimeVaryingOrTransformDependant || differentArgsOrShader || differentResources
                                    return dirty
                                }
                                if isDirty() {
                                    // TODO: Look at how binding inter-stage dependencies should work
                                    let renderResult = try renderCompute(stageId: stageId, stageIndex: index, geometry: geometry, shader: shader, computeTextureResources: currentResources)
                                    try updateDependantShaderStagesAndFreeResources(renderResult: renderResult, persistedShader: persistedShader, shaderSha256: shaderSha256, argsSha256: argsSha256)
                                }
                            }
                        }
                    }
                }
                
                for successorStage in item.dependants {
                    if let stage = stagesDict[successorStage], stage.id != item.id, hasNoDependencies(stage: stage) {
                        noDependencyStages.append(stage)
                    }
                }
                
                i += 1
                try Task.checkCancellation()
                await Task.yield()
            }
            try Task.checkCancellation()
            try await Task.sleep(nanoseconds: 16666666)
        }
    }
}


struct JelloPreviewBaker<Child : View> : View {
    @ViewBuilder let child: Child
    let graphId: UUID
    @Environment(\.modelContext) var modelContext

    @Query var graphs: [JelloGraph]
    @Query var nodes: [JelloNode]
    @Query var edges: [JelloEdge]
    @Query var data: [JelloNodeData]
    @State var generation: Int = 0
    @Query(sort: \JelloInputPort.index) var inputPorts: [JelloInputPort]
    @Query(sort: \JelloOutputPort.index) var outputPorts: [JelloOutputPort]
    
    init(graphId: UUID, child: @escaping () -> Child) {
        self.child = child()
        self.graphId = graphId
        self._graphs = Query(FetchDescriptor(predicate: #Predicate { $0.uuid == graphId }))
        self._nodes = Query(FetchDescriptor(predicate: #Predicate { $0.graph?.uuid == graphId }))
        self._edges = Query(FetchDescriptor(predicate: #Predicate { $0.graph?.uuid == graphId }))
    }
    
    private func dataChanged(){
        generation = generation + 1
    }
    
    var body: some View {
        child
            .onChange(of: graphs, initial: true, { _, _ in dataChanged() })
            .onChange(of: nodes, initial: false, { _, _ in dataChanged() })
            .onChange(of: edges, initial: false, { _, _ in dataChanged() })
            .onChange(of: data, initial: false, { _, _ in dataChanged() })
            .onChange(of: inputPorts, initial: false, { _, _ in dataChanged() })
            .onChange(of: outputPorts, initial: false, { _, _ in dataChanged() })
            .task(id: generation, priority: .medium, {
                let container = modelContext.container
                let previewBakerActor = JelloPreviewBakerActor(modelContainer: container)
                try? await previewBakerActor.compileAndDispatchComputeShaders(container, graphId: graphId)
            })
    }
}
