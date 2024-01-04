//
//  ShaderPreviewView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/04.
//

import SwiftUI
import Metal
import MetalKit

fileprivate struct ShaderPreviewViewRepresentable: UIViewRepresentable {
    let vertexShader: String?
    let fragmentShader: String
    let geometry: JelloPreviewGeometry
    let frame: CGRect
    
    init?(vertexShader: String?, fragmentShader: String, geometry: JelloPreviewGeometry, frame: CGRect){
        self.vertexShader = vertexShader
        self.fragmentShader = fragmentShader
        self.geometry = geometry
        self.frame = frame
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        let mtkView = uiView as! MTKView
        mtkView.frame = self.frame
    }
    
    func makeUIView(context: Context) -> some UIView {
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported")
        }
        let view = MTKView(frame: self.frame, device: defaultDevice)
        view.backgroundColor = UIColor.black
        context.coordinator.setup(metalKitView: view)
        context.coordinator.mtkView(view, drawableSizeWillChange: view.drawableSize)
        view.delegate = context.coordinator
        return view
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    
    class Coordinator: NSObject, MTKViewDelegate {
        func draw(in view: MTKView) {
        }
        
        func setup(metalKitView: MTKView){
            
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            
        }
    }
}


struct ShaderPreviewView: View {
    let vertexShader: String?
    let fragmentShader: String
    let previewGeometry: JelloPreviewGeometry
    
    var body: some View {
        GeometryReader { geometry in
            ShaderPreviewViewRepresentable(vertexShader: vertexShader, fragmentShader: fragmentShader, geometry: previewGeometry, frame: geometry.frame(in: .local))

        }
    }
}

