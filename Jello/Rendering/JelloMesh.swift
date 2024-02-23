//
//  JelloMesh.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/04.
//

import Foundation
import MetalKit
import simd


class JelloSubmesh : NSObject {
    internal init(modelIOSubmesh: MDLSubmesh, metalKitSubmesh: MTKSubmesh, metalKitTextureLoader: MTKTextureLoader) throws {
        self.metalKitSubmesh = metalKitSubmesh
        
        super.init()
    }
    
    let metalKitSubmesh: MTKSubmesh
}

class JelloMesh: NSObject {
    var metalKitMesh: MTKMesh
    var submeshes: Array<JelloSubmesh>

    internal init(modelIOMesh: MDLMesh, modelIOVertexDescriptor: MDLVertexDescriptor, metalKitTextureLoader: MTKTextureLoader, device: MTLDevice) throws {

        // Have ModelIO create the tangents from mesh texture coordinates and normals
        modelIOMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate, normalAttributeNamed: MDLVertexAttributeNormal, tangentAttributeNamed: MDLVertexAttributeTangent)
        
        // Have ModelIO create bitangents from mesh texture coordinates and the newly created tangents
        modelIOMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                                    tangentAttributeNamed: MDLVertexAttributeTangent, bitangentAttributeNamed: MDLVertexAttributeBitangent)
                
        // Apply the ModelIO vertex descriptor created to match the Metal vertex descriptor.
        // Assigning a new vertex descriptor to a ModelIO mesh performs a re-layout of the vertex
        //   vertex data.  In this case we created the ModelIO vertex descriptor so that the layout
        //   of the vertices in the ModelIO mesh match the layout of vertices the Metal render pipeline
        //   expects as input into its vertex shader
        // Note that this re-layout operation can only be performed after tangents and
        //   bitangents have been created.  This is because Model IO's addTangentBasis methods only works
        //   with vertex data is all in 32-bit floating-point.  The vertex descriptor applied here cans
        //   change those floats into 16-bit floats or other types from which ModelIO cannot produce
        //   tangents
        modelIOMesh.vertexDescriptor = modelIOVertexDescriptor
   
        // Create the metalKit mesh which will contain the Metal buffer(s) with the mesh's vertex data
        //   and submeshes with info to draw the mesh
        self.metalKitMesh = try MTKMesh(mesh: modelIOMesh, device: device)
        
        // There should always be the same number of MetalKit submeshes in the MetalKit mesh as there
        //   are Model IO submesnes in the ModelIO mesh
        assert(metalKitMesh.submeshes.count == modelIOMesh.submeshes?.count)

        // Create an array to hold this AAPLMesh object's AAPLSubmesh objects
        self.submeshes = Array()
        self.submeshes.reserveCapacity(metalKitMesh.submeshes.count)

        // Create an AAPLSubmesh object for each submesh and a add it to the submeshes array
        for i in 0..<metalKitMesh.submeshes.count {
            if let modelIOSubmesh = modelIOMesh.submeshes?.object(at: i) as? MDLSubmesh {
                let subMesh = try JelloSubmesh(modelIOSubmesh: modelIOSubmesh,
                                      metalKitSubmesh: metalKitMesh.submeshes[i],
                                      metalKitTextureLoader: metalKitTextureLoader)
                submeshes.append(subMesh)
            }

        }

        super.init()
    }
    
    
    private class func processObject(obj: MDLObject, modelIOVertexDescriptor: MDLVertexDescriptor, metalKitTextureLoader: MTKTextureLoader, device: MTLDevice) throws -> Array<JelloMesh> {
        var newMeshes: [JelloMesh] = Array();

        // If this ModelIO  object is a mesh object (not a camera, light, or soemthing else)...
        if let mesh = obj as? MDLMesh
        {
            let newMesh = try JelloMesh(modelIOMesh: mesh, modelIOVertexDescriptor: modelIOVertexDescriptor, metalKitTextureLoader:metalKitTextureLoader, device: device);
            newMeshes.append(newMesh)
        }

        // Recursively traverse the ModelIO  asset hierarchy to find ModelIO  meshes that are children
        //   of this ModelIO  object and create app-specific FPMesh objects from those ModelIO meshes
        if obj.conforms(to: MDLObjectContainerComponent.self) {
            for child in obj.children.objects
            {
                let childMeshes = try JelloMesh.processObject(obj: child, modelIOVertexDescriptor: modelIOVertexDescriptor, metalKitTextureLoader: metalKitTextureLoader, device: device)
                newMeshes.append(contentsOf: childMeshes)
            }
        }
            

        return newMeshes
    }
    
    
    
    class func load(url: URL, modelIOVertexDescriptor: MDLVertexDescriptor, device: MTLDevice) throws -> [JelloMesh]  {

        // Create a MetalKit mesh buffer allocator so that ModelIO  will load mesh data directly into
        // Metal buffers accessible by the GPU
        let bufferAllocator = MTKMeshBufferAllocator(device: device)

        // Use ModelIO  to load the model file at the URL.  This returns a ModelIO  asset object, which
        //   contains a hierarchy of ModelIO objects composing a "scene" described by the model file.
        //   This hierarchy may include lights, cameras, but, most importantly, mesh and submesh data
        //   that we'll render with Metal
        let asset = MDLAsset(url: url, vertexDescriptor: nil, bufferAllocator: bufferAllocator)
        
        
        // Create a MetalKit texture loader to load material textures from files or the asset catalog
        //   into Metal textures
        let textureLoader = MTKTextureLoader(device: device)

        var meshes: [JelloMesh] = Array();

        // Traverse the ModelIO asset hierarchy to find ModelIO meshes and create app-specific
        //   AAPLMesh objects from those ModelIO meshes
        for child in asset.childObjects(of: MDLObject.self)
        {
            let assetMeshes = try JelloMesh.processObject(obj: child, modelIOVertexDescriptor: modelIOVertexDescriptor, metalKitTextureLoader:textureLoader, device:device)
            meshes.append(contentsOf: assetMeshes)
        }
        
        return meshes;
    }

}

func loadPreviewGeometry(_ geometry: JelloPreviewGeometry, modelIOVertexDescriptor: MDLVertexDescriptor, device: MTLDevice) throws -> [JelloMesh] {
    var url: URL? = nil
    
    switch geometry {
        case .cube:
            url = Bundle.main.url(forResource: "Cube.obj", withExtension: nil)
        case .sphere:
            url = Bundle.main.url(forResource: "UV_Sphere.obj", withExtension: nil)
    }
    
    return try JelloMesh.load(url: url!, modelIOVertexDescriptor: modelIOVertexDescriptor, device: device)
}
