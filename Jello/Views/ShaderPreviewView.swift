//
//  ShaderPreviewView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/04.
//

import SwiftUI
import Metal
import MetalKit
import simd
import JelloCompilerStatic

let maxBuffersInFlight = 3


fileprivate struct ShaderPreviewViewRepresentable: UIViewRepresentable {
    let vertexShader: String
    let fragmentShader: String
    let geometry: JelloPreviewGeometry
    let frame: CGRect
    
    init(vertexShader: String, fragmentShader: String, geometry: JelloPreviewGeometry, frame: CGRect){
        self.vertexShader = vertexShader
        self.fragmentShader = fragmentShader
        self.geometry = geometry
        self.frame = frame
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        let mtkView = uiView as! MTKView
        mtkView.frame = self.frame
        context.coordinator.setShaders(metalKitView: mtkView, vertexShader: vertexShader, fragmentShader: fragmentShader)
    }
    
    func makeUIView(context: Context) -> some UIView {
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported")
        }
        assert(defaultDevice.supportsFamily(.apple4),
                 "Sample requires MTLGPUFamilyApple4 (only available on Macs with Apple Silicon or iOS devices with an A11 or later)")
        
        let view = MTKView(frame: self.frame, device: defaultDevice)
        view.depthStencilPixelFormat = .invalid
        view.backgroundColor = UIColor.black
        context.coordinator.setup(metalKitView: view, vertexShader: vertexShader, fragmentShader: fragmentShader)
        context.coordinator.setShaders(metalKitView: view, vertexShader: vertexShader, fragmentShader: fragmentShader)
        context.coordinator.mtkView(view, drawableSizeWillChange: view.drawableSize)
        view.delegate = context.coordinator
        return view
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    
    class Coordinator: NSObject, MTKViewDelegate {

        var drawableSize: CGSize = CGSizeZero
        var vertexDescriptor: MTLVertexDescriptor? = nil
        var depthPrePassPipelineState: MTLRenderPipelineState? = nil
        var forwardLightingPipelineState: MTLRenderPipelineState? = nil
        var frameDataBuffers: [MTLBuffer] = Array()
        let inFlightSemaphore = DispatchSemaphore(value: 2)
        var nearPlane: Float = 0.1
        var farPlane: Float = 1000
        var fov: Float = 60.0 * (.pi / 180.0)
        var currentBufferIndex: Int = 0
        var projectionMatrix: matrix_float4x4 = matrix_float4x4()
        var rotation: Float = 0
        var meshes: [JelloMesh] = []
        var viewRenderPassDescriptor: MTLRenderPassDescriptor? = nil
        var commandQueue: MTLCommandQueue?
        var relaxedDepthState: MTLDepthStencilState? = nil

        
        func updateFrameState(){
            self.currentBufferIndex = (self.currentBufferIndex + 1) % maxBuffersInFlight
            var frameData = frameDataBuffers[currentBufferIndex].contents().load(as: FrameDataC.self);

            // Update ambient light color.
            let ambientLightColor = vector_float3(0.05, 0.05, 0.05)
            frameData.ambientLightColor = ambientLightColor

            // Update directional light direction in world space.
            let directionalLightDirection = vector_float3(1.0, -1.0, 1.0)
            frameData.directionalLightDirection = directionalLightDirection

            // Update directional light color.
            let directionalLightColor = vector_float3(0.4, 0, 0.2)
            frameData.directionalLightColor = directionalLightColor

            // Set projection matrix and calculate inverted projection matrix.
            frameData.projectionMatrix = projectionMatrix
            frameData.projectionMatrixInv = projectionMatrix.inverse
            frameData.depthUnproject = vector2(farPlane / (farPlane - nearPlane), (-farPlane * nearPlane) / (farPlane - nearPlane))

            // Set screen dimensions.
            frameData.framebufferWidth = UInt32(drawableSize.width)
            frameData.framebufferHeight = UInt32(drawableSize.height)

            let fovScale = tanf(0.5 * fov) * 2.0;
            let aspectRatio = Float(frameData.framebufferWidth) / Float(frameData.framebufferHeight)
            frameData.screenToViewSpace = vector_float3(fovScale / Float(frameData.framebufferHeight), -fovScale * 0.5 * aspectRatio, -fovScale * 0.5)

            // Calculate new view matrix and inverted view matrix.
            frameData.viewMatrix = matrix_multiply(matrix4x4_translation(-0, -0, 3),
                                                   matrix_multiply(matrix4x4_rotation(radians: 0, axis: vector_float3(1,0,0)),
                                                                   matrix4x4_rotation(radians: 0, axis:vector_float3(0,1,0))))
            frameData.viewMatrixInv = frameData.viewMatrix.inverse

            let rotationAxis = vector_float3(0, 1, 0);
            var modelMatrix = matrix4x4_rotation(radians:0, axis: rotationAxis)
            let translation = matrix4x4_translation(0.0, 0, 0)
            modelMatrix = matrix_multiply(modelMatrix, translation)

            frameData.modelViewMatrix = matrix_multiply(frameData.viewMatrix, modelMatrix)
            frameData.modelMatrix = modelMatrix

            frameData.normalMatrix = matrix3x3_upper_left(frameData.modelViewMatrix)
            frameData.normalMatrix = frameData.normalMatrix.transpose.inverse
            
            rotation += 0.002;
            
            withUnsafePointer(to: frameData){
                frameDataBuffers[currentBufferIndex].contents().copyMemory(from: $0, byteCount: MemoryLayout<FrameDataC>.size)
            }

        }
        
        func drawMeshes(_ renderEncoder: MTLRenderCommandEncoder)
        {
            for mesh in meshes
            {
                let metalKitMesh = mesh.metalKitMesh;

                // Set the mesh's vertex buffers.
                for bufferIndex in 0..<metalKitMesh.vertexBuffers.count {
                    let vertexBuffer = metalKitMesh.vertexBuffers[bufferIndex];
                    if(vertexBuffer.length > 0){
                        renderEncoder.setVertexBuffer(vertexBuffer.buffer,  offset:vertexBuffer.offset, index:bufferIndex);
                    }
                }

                // Draw each submesh of the mesh.
                for submesh in mesh.submeshes
                {
                    // Set any textures that you read or sample in the render pipeline.

                    let metalKitSubmesh = submesh.metalKitSubmesh;

                    renderEncoder.drawIndexedPrimitives(type: metalKitSubmesh.primitiveType,
                                              indexCount:metalKitSubmesh.indexCount,
                                               indexType:metalKitSubmesh.indexType,
                                             indexBuffer:metalKitSubmesh.indexBuffer.buffer,
                                       indexBufferOffset:metalKitSubmesh.indexBuffer.offset
                    );
                }
            }
        }
        
        func draw(in view: MTKView) {
            /// Per frame updates hare
            
            _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
            
            if let commandBuffer = commandQueue!.makeCommandBuffer() {
                
                let semaphore = inFlightSemaphore
                commandBuffer.addCompletedHandler { (_ commandBuffer)-> Swift.Void in
                    semaphore.signal()
                }
                
                self.updateFrameState()
                
                /// Delay getting the currentRenderPassDescriptor until we absolutely need it to avoid
                /// holding onto the drawable and blocking the display pipeline any longer than necessary
                
                    // Check if there is a drawable to render content to.
                    if let drawableTexture = view.currentDrawable?.texture {
                        //                    if(FPNumSamples > 1)
                        //                    {
//                        viewRenderPassDescriptor!.colorAttachments[0].resolveTexture = view.currentDrawable!.texture;
                        //                    }
                        //                    else
                        //                    {

                        viewRenderPassDescriptor!.colorAttachments[0].texture = drawableTexture
                        
                        if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: viewRenderPassDescriptor!) {
                            renderEncoder.setCullMode(.back);

                            // Render scene to depth buffer only. You later use this data to determine the minimum and
                            // maximum depth values of each tile.

                            // Render objects with lighting.
                            renderEncoder.pushDebugGroup("Render Forward Lighting");
                            renderEncoder.setRenderPipelineState(forwardLightingPipelineState!);
                            renderEncoder.setDepthStencilState(relaxedDepthState);
                            renderEncoder.setVertexBuffer(frameDataBuffers[currentBufferIndex], offset:0, index: 2)
//                            renderEncoder.setFragmentBuffer(frameDataBuffers[currentBufferIndex], offset:0, index: 2)
                            self.drawMeshes(renderEncoder);
                            renderEncoder.popDebugGroup();

                            renderEncoder.endEncoding()
                    }

                }
                
                if let drawable = view.currentDrawable {
                    commandBuffer.present(drawable)
                }
                
                commandBuffer.commit()

            }
        }
        
        func setup(metalKitView: MTKView, vertexShader: String, fragmentShader: String){
            self.frameDataBuffers.reserveCapacity(maxBuffersInFlight)
            let device = metalKitView.device!

            let storageMode = MTLResourceOptions.storageModeShared
            self.frameDataBuffers.reserveCapacity(maxBuffersInFlight)
            for i in 0..<maxBuffersInFlight {
                let idxStr = String(i)
                self.frameDataBuffers.append(device.makeBuffer(length: MemoryLayout<FrameDataC>.size, options: storageMode)!)
                self.frameDataBuffers[i].label = "FrameDataBuffer"+idxStr
            }
            
            
            self.vertexDescriptor = MTLVertexDescriptor()

            // Positions.
            vertexDescriptor!.attributes[0].format = .float3
            vertexDescriptor!.attributes[0].offset = 0
            vertexDescriptor!.attributes[0].bufferIndex = 0

            // Texture coordinates.
            vertexDescriptor!.attributes[1].format = .float2
            vertexDescriptor!.attributes[1].offset = 12
            vertexDescriptor!.attributes[1].bufferIndex = 0

            // Normals.
            vertexDescriptor!.attributes[2].format = .float3
            vertexDescriptor!.attributes[2].offset = 20
            vertexDescriptor!.attributes[2].bufferIndex = 0

            // Tangents.
            vertexDescriptor!.attributes[3].format = .float3
            vertexDescriptor!.attributes[3].offset = 32
            vertexDescriptor!.attributes[3].bufferIndex = 0

            // Bitangents.
            vertexDescriptor!.attributes[4].format = .float3
            vertexDescriptor!.attributes[4].offset = 44
            vertexDescriptor!.attributes[4].bufferIndex = 0

            // Generic attribute buffer layout.
            vertexDescriptor!.layouts[0].stride = 56

            
            metalKitView.colorPixelFormat = .bgra8Unorm_srgb
            
            // Set view's depth stencil pixel format to Invalid.  This app will manually manage it's own
            // depth buffer, not depend on the depth buffer managed by MTKView
            metalKitView.depthStencilPixelFormat = .invalid;

            setShaders(metalKitView: metalKitView, vertexShader: vertexShader, fragmentShader: fragmentShader)
            
            
            let depthStateDesc = MTLDepthStencilDescriptor()

            // Create a depth state with depth buffer write enabled.
                    
            // Create a depth state with depth buffer write disabled and set the comparison function to
            //   `MTLCompareFunctionLessEqual`.
            
            // The comparison function is `MTLCompareFunctionLessEqual` instead of `MTLCompareFunctionLess`.
            //   The geometry pass renders to a pre-populated depth buffer (depth pre-pass) so each
            //   fragment needs to pass if its z-value is equal to the existing value already in the
            //   depth buffer.
            depthStateDesc.depthCompareFunction = .always
            depthStateDesc.isDepthWriteEnabled = false
            self.relaxedDepthState = device.makeDepthStencilState(descriptor: depthStateDesc)!
            
            self.viewRenderPassDescriptor = MTLRenderPassDescriptor();
            self.viewRenderPassDescriptor!.colorAttachments[0].loadAction = .clear
            self.viewRenderPassDescriptor!.depthAttachment.loadAction = .clear
            self.viewRenderPassDescriptor!.depthAttachment.storeAction = .dontCare
            self.viewRenderPassDescriptor!.stencilAttachment.loadAction = .clear
            self.viewRenderPassDescriptor!.stencilAttachment.storeAction = .dontCare
            self.viewRenderPassDescriptor!.depthAttachment.clearDepth = 1.0
            self.viewRenderPassDescriptor!.stencilAttachment.clearStencil = 0
            
            self.viewRenderPassDescriptor!.colorAttachments[0].storeAction = .store

            let queue = metalKitView.device!.makeCommandQueue()!
            self.commandQueue = queue
            
            // Starting to load assets
            
            // Creata a Model I/O vertex descriptor so that the format and layout of Model I/O mesh vertices
            //   fits the Metal render pipeline's vertex descriptor layout.
            let modelIOVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(vertexDescriptor!)
            
            // Indicate how each Metal vertex descriptor attribute maps to each Model I/O attribute.
            (modelIOVertexDescriptor.attributes[0] as! MDLVertexAttribute).name  = MDLVertexAttributePosition
            (modelIOVertexDescriptor.attributes[1] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
            (modelIOVertexDescriptor.attributes[2] as! MDLVertexAttribute).name = MDLVertexAttributeNormal
            (modelIOVertexDescriptor.attributes[3] as! MDLVertexAttribute).name  = MDLVertexAttributeTangent
            (modelIOVertexDescriptor.attributes[4] as! MDLVertexAttribute).name = MDLVertexAttributeBitangent

            let modelFileURL = Bundle.main.url(forResource: "UV_Sphere.obj", withExtension: nil)
            assert(modelFileURL != nil, "Could not find model UV_Sphere.obj file in bundle")
            
            // Create a MetalKit mesh buffer allocator so that ModelIO  will load mesh data directly into
            //   Metal buffers accessible by the GPU
            do {
                self.meshes = try JelloMesh.load(url: modelFileURL!, modelIOVertexDescriptor: modelIOVertexDescriptor, device: metalKitView.device!)
            } catch {
                self.meshes = Array()
            }

        }
        
        func setShaders(metalKitView: MTKView, vertexShader: String, fragmentShader: String) {
            let compileOptions = MTLCompileOptions()
            let renderPipelineStateDescriptor = MTLRenderPipelineDescriptor()

            renderPipelineStateDescriptor.vertexDescriptor = self.vertexDescriptor!
            renderPipelineStateDescriptor.rasterSampleCount = Int(1)

            renderPipelineStateDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat

            let vertexLibrary = try! metalKitView.device!.makeLibrary(source: vertexShader, options: compileOptions)
            let fragmentLibrary = try! metalKitView.device!.makeLibrary(source: fragmentShader, options: compileOptions)
            
            let vertexFunction = vertexLibrary.makeFunction(name: "vertexMain")
            let fragmentFunction = fragmentLibrary.makeFunction(name: "fragmentMain")
            
            renderPipelineStateDescriptor.label = "Preview"
            renderPipelineStateDescriptor.vertexDescriptor = vertexDescriptor
            renderPipelineStateDescriptor.vertexFunction = vertexFunction
            renderPipelineStateDescriptor.fragmentFunction = fragmentFunction
            try! self.forwardLightingPipelineState = metalKitView.device!.makeRenderPipelineState(descriptor: renderPipelineStateDescriptor)
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            self.drawableSize = size

            // Update the aspect ratio and projection matrix because the view orientation
            //   or size has changed.
            let aspect = Float(size.width) / Float(size.height)
            self.fov = 60.0 * (.pi / 180.0)
            self.nearPlane = 0.1
            self.farPlane = 50.0
            self.projectionMatrix = matrix_perspective_left_hand(fovyRadians: self.fov, aspectRatio: aspect, nearZ: nearPlane, farZ: farPlane);
        }
    }
}

func matrix_make_columns(_ col0:vector_float3, _ col1:vector_float3 , _ col2: vector_float3) -> matrix_float3x3 {
    return matrix_float3x3(col0, col1, col2);
}

func matrix3x3_upper_left(_ m: matrix_float4x4) -> matrix_float3x3 {
    let x = vector_float3(m.columns.0.x,m.columns.0.y, m.columns.0.z);
    let y = vector_float3(m.columns.1.x,m.columns.1.y, m.columns.1.z);
    let z = vector_float3(m.columns.2.x,m.columns.2.y, m.columns.2.z);
    return matrix_make_columns(x, y, z);
}

// Generic matrix math utility functions
func matrix4x4_rotation(radians: Float, axis: SIMD3<Float>) -> matrix_float4x4 {
    let unitAxis = normalize(axis)
    let ct = cosf(radians)
    let st = sinf(radians)
    let ci = 1 - ct
    let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
    return matrix_float4x4(columns:(vector_float4(    ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
                                         vector_float4(x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0),
                                         vector_float4(x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0),
                                         vector_float4(                  0,                   0,                   0, 1)))
}

func matrix4x4_translation(_ translationX: Float, _ translationY: Float, _ translationZ: Float) -> matrix_float4x4 {
    return matrix_float4x4(columns:(vector_float4(1, 0, 0, 0),
                                         vector_float4(0, 1, 0, 0),
                                         vector_float4(0, 0, 1, 0),
                                         vector_float4(translationX, translationY, translationZ, 1)))
}



func matrix_perspective_left_hand(fovyRadians fovy: Float, aspectRatio: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
    let ys = 1 / tanf(fovy * 0.5)
    let xs = ys / aspectRatio
    let zs = farZ / (farZ - nearZ)
    return matrix_float4x4(columns:(vector_float4(xs,  0, 0,   0),
                                         vector_float4( 0, ys, 0,   0),
                                         vector_float4( 0,  0, zs, 1),
                                         vector_float4( 0,  0, -nearZ*zs, 0)))
}


func radians_from_degrees(_ degrees: Float) -> Float {
    return (degrees / 180) * .pi
}

struct ShaderPreviewView: View {
    let vertexShader: String
    let fragmentShader: String
    let previewGeometry: JelloPreviewGeometry
    
    var body: some View {
        GeometryReader { geometry in
            ShaderPreviewViewRepresentable(vertexShader: vertexShader, fragmentShader: fragmentShader, geometry: previewGeometry, frame: .init(origin: .zero, size: geometry.size))
        }
    }
}
