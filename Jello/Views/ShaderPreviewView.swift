//
//  ShaderPreviewView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/04.
//

import SwiftUI
import SwiftData
import Metal
import MetalKit
import simd
import JelloCompilerStatic

//let maxBuffersInFlight = 3
//
//fileprivate struct ShaderPreviewViewRepresentable: UIViewRepresentable {
//    let vertexShader: MslSpirvVertexShaderOutput
//    let fragmentShader: MslSpirvFragmentShaderOutput
//    let geometry: JelloPreviewGeometry
//    let frame: CGRect
//    
//    init(vertexShader: MslSpirvVertexShaderOutput, fragmentShader: MslSpirvFragmentShaderOutput, geometry: JelloPreviewGeometry, frame: CGRect){
//        self.vertexShader = vertexShader
//        self.fragmentShader = fragmentShader
//        self.geometry = geometry
//        self.frame = frame
//    }
//    
//    func updateUIView(_ uiView: UIViewType, context: Context) {
//        let mtkView = uiView as! MTKView
//        mtkView.frame = self.frame
//        context.coordinator.setShaders(metalKitView: mtkView, vertexShader: vertexShader, fragmentShader: fragmentShader)
//        context.coordinator.setPreviewGeometry(geometry)
//    }
//    
//    func makeUIView(context: Context) -> some UIView {
//        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
//            fatalError("Metal is not supported")
//        }
//        assert(defaultDevice.supportsFamily(.apple4),
//                 "Application requires MTLGPUFamilyApple4 (only available on Macs with Apple Silicon or iOS devices with an A11 or later)")
//        
//        let view = MTKView(frame: self.frame, device: defaultDevice)
//        view.depthStencilPixelFormat = .depth32Float
//        view.backgroundColor = UIColor.black
//        context.coordinator.setup(metalKitView: view, vertexShader: vertexShader, fragmentShader: fragmentShader)
//        context.coordinator.setShaders(metalKitView: view, vertexShader: vertexShader, fragmentShader: fragmentShader)
//        context.coordinator.mtkView(view, drawableSizeWillChange: view.drawableSize)
//        context.coordinator.setPreviewGeometry(geometry)
//        view.delegate = context.coordinator
//        return view
//    }
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//    
//    
//    class Coordinator: NSObject, MTKViewDelegate {
//        var nearPlane: Float = 1
//        var farPlane: Float = 4
//        var fov: Float = 60.0 * (.pi / 180.0)
//        private var device: MTLDevice? = nil
//        private var drawableSize: CGSize = CGSizeZero
//        private var vertexDescriptor: MTLVertexDescriptor? = nil
//        private var mainPipelineState: MTLRenderPipelineState? = nil
//        private var frameDataBuffers: [MTLBuffer] = Array()
//        private let inFlightSemaphore = DispatchSemaphore(value: 2)
//        private var currentBufferIndex: Int = 0
//        private var projectionMatrix: matrix_float4x4 = matrix_float4x4()
//        private var rotation: Float = 0
//        private var meshes: [JelloMesh] = []
//        private var modelIOVertexDescriptor: MDLVertexDescriptor? = nil
//        var viewRenderPassDescriptor: MTLRenderPassDescriptor? = nil
//        var commandQueue: MTLCommandQueue?
//        var depthState: MTLDepthStencilState? = nil
//
//        
//        func setPreviewGeometry(_ geometry: JelloPreviewGeometry){
//            meshes = try! loadPreviewGeometry(geometry, modelIOVertexDescriptor: modelIOVertexDescriptor!, device: device!)
//        }
//        
//        func updateFrameState(){
//            self.currentBufferIndex = (self.currentBufferIndex + 1) % maxBuffersInFlight
//            var frameData = frameDataBuffers[currentBufferIndex].contents().load(as: FrameDataC.self);
//
//            // Update ambient light color.x
//            let ambientLightColor = vector_float3(0.05, 0.05, 0.05)
//            frameData.ambientLightColor = ambientLightColor
//
//            // Update directional light direction in world space.
//            let directionalLightDirection = vector_float3(1.0, -1.0, 1.0)
//            frameData.directionalLightDirection = directionalLightDirection
//
//            // Update directional light color.
//            let directionalLightColor = vector_float3(0.4, 0, 0.2)
//            frameData.directionalLightColor = directionalLightColor
//
//            // Set projection matrix and calculate inverted projection matrix.
//            frameData.projectionMatrix = projectionMatrix
//            frameData.projectionMatrixInv = projectionMatrix.inverse
//            frameData.depthUnproject = vector2(farPlane / (farPlane - nearPlane), (-farPlane * nearPlane) / (farPlane - nearPlane))
//
//            // Set screen dimensions.
//            frameData.framebufferWidth = UInt32(drawableSize.width)
//            frameData.framebufferHeight = UInt32(drawableSize.height)
//
//            let fovScale = tanf(0.5 * fov) * 2.0;
//            let aspectRatio = Float(frameData.framebufferWidth) / Float(frameData.framebufferHeight)
//            frameData.screenToViewSpace = vector_float3(fovScale / Float(frameData.framebufferHeight), -fovScale * 0.5 * aspectRatio, -fovScale * 0.5)
//
//            // Calculate new view matrix and inverted view matrix.
//            frameData.viewMatrix = matrix_multiply(matrix4x4_translation(-0, -0.3, 3),
//                                                   matrix_multiply(matrix4x4_rotation(radians: 0, axis: vector_float3(1,0,0)),
//                                                                   matrix4x4_rotation(radians: rotation, axis:vector_float3(0,1,0))))
//            frameData.viewMatrixInv = frameData.viewMatrix.inverse
//
//            let rotationAxis = vector_float3(0, 1, 0);
//            var modelMatrix = matrix4x4_rotation(radians:0, axis: rotationAxis)
//            let translation = matrix4x4_translation(0.0, 0, 0)
//            modelMatrix = matrix_multiply(modelMatrix, translation)
//
//            frameData.modelViewMatrix = matrix_multiply(frameData.viewMatrix, modelMatrix)
//            frameData.modelMatrix = modelMatrix
//
//            frameData.normalMatrix = matrix3x3_upper_left(frameData.modelViewMatrix)
//            frameData.normalMatrix = frameData.normalMatrix.transpose.inverse
//            
//            rotation += 0.002;
//            
//            withUnsafePointer(to: frameData){
//                frameDataBuffers[currentBufferIndex].contents().copyMemory(from: $0, byteCount: MemoryLayout<FrameDataC>.size)
//            }
//
//        }
//        
//        func drawMesh(_ renderEncoder: MTLRenderCommandEncoder)
//        {
//            for msh in self.meshes {
//                let metalKitMesh = msh.metalKitMesh
//                
//                // Set the mesh's vertex buffers.
//                for bufferIndex in 0..<metalKitMesh.vertexBuffers.count {
//                    let vertexBuffer = metalKitMesh.vertexBuffers[bufferIndex];
//                    if(vertexBuffer.length > 0){
//                        renderEncoder.setVertexBuffer(vertexBuffer.buffer,  offset:vertexBuffer.offset, index:bufferIndex);
//                    }
//                }
//                
//                // Draw each submesh of the mesh.
//                for submesh in msh.submeshes
//                {
//                    // Set any textures that you read or sample in the render pipeline.
//                    
//                    let metalKitSubmesh = submesh.metalKitSubmesh;
//                    
//                    renderEncoder.drawIndexedPrimitives(type: metalKitSubmesh.primitiveType,
//                                                        indexCount:metalKitSubmesh.indexCount,
//                                                        indexType:metalKitSubmesh.indexType,
//                                                        indexBuffer:metalKitSubmesh.indexBuffer.buffer,
//                                                        indexBufferOffset:metalKitSubmesh.indexBuffer.offset
//                    );
//                }
//            }
//        }
//        
//        func draw(in view: MTKView) {
//            /// Per frame updates hare
//            
//            _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
//            
//            if let commandBuffer = commandQueue!.makeCommandBuffer() {
//                
//                let semaphore = inFlightSemaphore
//                commandBuffer.addCompletedHandler { (_ commandBuffer)-> Swift.Void in
//                    semaphore.signal()
//                }
//                
//                self.updateFrameState()
//                
//                /// Delay getting the currentRenderPassDescriptor until we absolutely need it to avoid
//                /// holding onto the drawable and blocking the display pipeline any longer than necessary
//                
//                    // Check if there is a drawable to render content to.
//                    if let drawableTexture = view.currentDrawable?.texture {
//                        viewRenderPassDescriptor!.colorAttachments[0].texture = drawableTexture
//                        viewRenderPassDescriptor!.depthAttachment.texture = view.depthStencilTexture
//                        if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: viewRenderPassDescriptor!) {
//                            renderEncoder.setCullMode(.back);
//
//                            // Render objects with lighting.
//                            renderEncoder.pushDebugGroup("Render Forward Lighting");
//                            renderEncoder.setRenderPipelineState(mainPipelineState!);
//                            renderEncoder.setDepthStencilState(depthState);
//                            renderEncoder.setVertexBuffer(frameDataBuffers[currentBufferIndex], offset:0, index: 2)
////                            renderEncoder.setFragmentBuffer(frameDataBuffers[currentBufferIndex], offset:0, index: 2)
//                            self.drawMesh(renderEncoder);
//                            renderEncoder.popDebugGroup();
//
//                            renderEncoder.endEncoding()
//                    }
//                }
//                
//                if let drawable = view.currentDrawable {
//                    commandBuffer.present(drawable)
//                }
//                
//                commandBuffer.commit()
//
//            }
//        }
//        
//        func setup(metalKitView: MTKView, vertexShader: MslSpirvVertexShaderOutput, fragmentShader: MslSpirvFragmentShaderOutput){
//            self.frameDataBuffers.reserveCapacity(maxBuffersInFlight)
//            self.device = metalKitView.device!
//
//            let storageMode = MTLResourceOptions.storageModeShared
//            self.frameDataBuffers.reserveCapacity(maxBuffersInFlight)
//            for i in 0..<maxBuffersInFlight {
//                let idxStr = String(i)
//                self.frameDataBuffers.append(device!.makeBuffer(length: MemoryLayout<FrameDataC>.size, options: storageMode)!)
//                self.frameDataBuffers[i].label = "FrameDataBuffer"+idxStr
//            }
//            
//            
//            self.vertexDescriptor = MTLVertexDescriptor()
//
//            // Positions.
//            vertexDescriptor!.attributes[0].format = .float3
//            vertexDescriptor!.attributes[0].offset = 0
//            vertexDescriptor!.attributes[0].bufferIndex = 0
//
//            // Texture coordinates.
//            vertexDescriptor!.attributes[1].format = .float2
//            vertexDescriptor!.attributes[1].offset = 12
//            vertexDescriptor!.attributes[1].bufferIndex = 0
//
//            // Normals.
//            vertexDescriptor!.attributes[2].format = .float3
//            vertexDescriptor!.attributes[2].offset = 20
//            vertexDescriptor!.attributes[2].bufferIndex = 0
//
//            // Tangents.
//            vertexDescriptor!.attributes[3].format = .float3
//            vertexDescriptor!.attributes[3].offset = 32
//            vertexDescriptor!.attributes[3].bufferIndex = 0
//
//            // Bitangents.
//            vertexDescriptor!.attributes[4].format = .float3
//            vertexDescriptor!.attributes[4].offset = 44
//            vertexDescriptor!.attributes[4].bufferIndex = 0
//
//            // Generic attribute buffer layout.
//            vertexDescriptor!.layouts[0].stride = 56
//
//            
//            metalKitView.colorPixelFormat = .bgra8Unorm_srgb
//            
//            // Set view's depth stencil pixel format to Invalid.  This app will manually manage it's own
//            // depth buffer, not depend on the depth buffer managed by MTKView
//            metalKitView.depthStencilPixelFormat = .depth32Float
//
//            setShaders(metalKitView: metalKitView, vertexShader: vertexShader, fragmentShader: fragmentShader)
//            
//            
//            let depthStateDesc = MTLDepthStencilDescriptor()
//
//            // Create a depth state with depth buffer write enabled.
//                    
//            // Create a depth state with depth buffer write disabled and set the comparison function to
//            //   `MTLCompareFunctionLessEqual`.
//            
//            depthStateDesc.depthCompareFunction = .less
//            depthStateDesc.isDepthWriteEnabled = true
//            self.depthState = device!.makeDepthStencilState(descriptor: depthStateDesc)!
//            
//            self.viewRenderPassDescriptor = MTLRenderPassDescriptor();
//            self.viewRenderPassDescriptor!.colorAttachments[0].loadAction = .clear
//            self.viewRenderPassDescriptor!.depthAttachment.loadAction = .clear
//            self.viewRenderPassDescriptor!.depthAttachment.storeAction = .dontCare
//            self.viewRenderPassDescriptor!.stencilAttachment.loadAction = .clear
//            self.viewRenderPassDescriptor!.stencilAttachment.storeAction = .dontCare
//            self.viewRenderPassDescriptor!.depthAttachment.clearDepth = 1.0
//            self.viewRenderPassDescriptor!.stencilAttachment.clearStencil = 0
//            
//            self.viewRenderPassDescriptor!.colorAttachments[0].storeAction = .store
//
//            let queue = metalKitView.device!.makeCommandQueue()!
//            self.commandQueue = queue
//            
//            // Starting to load assets
//            
//            // Creata a Model I/O vertex descriptor so that the format and layout of Model I/O mesh vertices
//            //   fits the Metal render pipeline's vertex descriptor layout.
//            self.modelIOVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(vertexDescriptor!)
//            // Indicate how each Metal vertex descriptor attribute maps to each Model I/O attribute.
//            (modelIOVertexDescriptor!.attributes[0] as! MDLVertexAttribute).name  = MDLVertexAttributePosition
//            (modelIOVertexDescriptor!.attributes[1] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
//            (modelIOVertexDescriptor!.attributes[2] as! MDLVertexAttribute).name = MDLVertexAttributeNormal
//            (modelIOVertexDescriptor!.attributes[3] as! MDLVertexAttribute).name  = MDLVertexAttributeTangent
//            (modelIOVertexDescriptor!.attributes[4] as! MDLVertexAttribute).name = MDLVertexAttributeBitangent
//        }
//        
//        func setShaders(metalKitView: MTKView, vertexShader: MslSpirvVertexShaderOutput, fragmentShader: MslSpirvFragmentShaderOutput) {
//            let compileOptions = MTLCompileOptions()
//            let renderPipelineStateDescriptor = MTLRenderPipelineDescriptor()
//
//            renderPipelineStateDescriptor.vertexDescriptor = self.vertexDescriptor!
//            renderPipelineStateDescriptor.rasterSampleCount = Int(1)
//
//            renderPipelineStateDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
//            renderPipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float
//
//            let vertexLibrary = try! metalKitView.device!.makeLibrary(source: vertexShader.shader, options: compileOptions)
//            let fragmentLibrary = try! metalKitView.device!.makeLibrary(source: fragmentShader.shader, options: compileOptions)
//            
//            let vertexFunction = vertexLibrary.makeFunction(name: "vertexMain")
//            let fragmentFunction = fragmentLibrary.makeFunction(name: "fragmentMain")
//            
//            renderPipelineStateDescriptor.label = "Preview"
//            renderPipelineStateDescriptor.vertexDescriptor = vertexDescriptor
//            renderPipelineStateDescriptor.vertexFunction = vertexFunction
//            renderPipelineStateDescriptor.fragmentFunction = fragmentFunction
//            try! self.mainPipelineState = metalKitView.device!.makeRenderPipelineState(descriptor: renderPipelineStateDescriptor)
//        }
//        
//        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
//            self.drawableSize = size
//
//            // Update the aspect ratio and projection matrix because the view orientation
//            //   or size has changed.
//            let aspect = Float(size.width) / Float(size.height)
//            self.projectionMatrix = matrix_perspective_left_hand(fovyRadians: self.fov, aspectRatio: aspect, nearZ: nearPlane, farZ: farPlane);
//        }
//    }
//}
//


//struct ShaderPreviewView: View {
//    let vertexShader: MslSpirvVertexShaderOutput
//    let fragmentShader: MslSpirvFragmentShaderOutput
//    let previewGeometry: JelloPreviewGeometry
//    
//    init(vertexShader: MslSpirvVertexShaderOutput, fragmentShader: MslSpirvFragmentShaderOutput, previewGeometry: JelloPreviewGeometry) {
//        self.vertexShader = vertexShader
//        self.fragmentShader = fragmentShader
//        self.previewGeometry = previewGeometry
//        
//    }
//    
//    var body: some View {
//        GeometryReader { geometry in
//            ShaderPreviewViewRepresentable(vertexShader: vertexShader, fragmentShader: fragmentShader, geometry: previewGeometry, frame: .init(origin: .zero, size: geometry.size))
//        }
//    }
//}
