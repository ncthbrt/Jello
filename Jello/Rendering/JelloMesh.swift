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
        self.textures = Array(repeating: nil, count: 0)
        
        if(modelIOSubmesh.material != nil) {
            
//            self.textures[FPTextureIndices.textureIndexBaseColor.rawValue] = try JelloSubmesh.createMetalTextureFromMaterial(
//                material: modelIOSubmesh.material!,
//                modelIOMaterialSemantic: MDLMaterialSemantic.baseColor,
//                metalKitTextureLoader: metalKitTextureLoader
//            )
//            self.textures[FPTextureIndices.textureIndexSpecular.rawValue] = try JelloSubmesh.createMetalTextureFromMaterial(
//                material: modelIOSubmesh.material!,
//                modelIOMaterialSemantic: MDLMaterialSemantic.specular,
//                metalKitTextureLoader: metalKitTextureLoader
//            )
//            
//            self.textures[FPTextureIndices.textureIndexNormal.rawValue] = try JelloSubmesh.createMetalTextureFromMaterial(
//                material: modelIOSubmesh.material!,
//                modelIOMaterialSemantic: MDLMaterialSemantic.tangentSpaceNormal,
//                metalKitTextureLoader: metalKitTextureLoader
//            )
        }
        
        super.init()
    }
    
    class func createMetalTextureFromMaterial(material: MDLMaterial, modelIOMaterialSemantic: MDLMaterialSemantic, metalKitTextureLoader: MTKTextureLoader) throws -> MTLTexture? {
        
        var newTexture: MTLTexture!
        
        for property in material.properties(with: modelIOMaterialSemantic) {
            // Load the textures with shader read using private storage
            let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [
            .textureUsage: MTLTextureUsage.shaderRead.rawValue,
            .textureStorageMode: MTLStorageMode.private.rawValue]
            
            switch property.type {
            case .string:
                if let stringValue = property.stringValue {
                    
                    // If not texture has been fround by interpreting the URL as a path,  interpret
                    // string as an asset catalog name and attempt to load it with
                    //  -[MTKTextureLoader newTextureWithName:scaleFactor:bundle:options::error:]
                    // If a texture with the by interpreting the URL as an asset catalog name
                    if let texture = try? metalKitTextureLoader.newTexture(name: stringValue, scaleFactor: 1.0, bundle: nil, options: textureLoaderOptions) {
                        newTexture = texture
                    }
                }
            case .URL:
                if let textureURL = property.urlValue {
                    // Attempt to load the texture from the file system
                    // If the texture has been found for a material using the string as a file path name...
                    if let texture = try? metalKitTextureLoader.newTexture(URL: textureURL, options: textureLoaderOptions) {
                        newTexture = texture
                    }
                }
            default:
                // If we did not find the texture by interpreting it as a file path or as an asset name in the asset catalog, something went wrong
                // (Perhaps the file was missing or misnamed in the asset catalog, model/material file, or file system)
                // Depending on how the Metal render pipeline use with this submesh is implemented, this condition can be handled more gracefully.
                // The app could load a dummy texture that will look okay when set with the pipeline or ensure that the pipelines rendering
                // this submesh does not require a material with this property.
                 
                fatalError("Texture data for material property not found.")
            }
        }
        return newTexture
    }
    
    let metalKitSubmesh: MTKSubmesh
    var textures: Array<MTLTexture?>
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
    
    
    
    class func load(url: URL, modelIOVertexDescriptor: MDLVertexDescriptor, device: MTLDevice) throws -> Array<JelloMesh>  {

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

