//
//  PreviewNodeView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/03.
//

import SwiftUI
import MetalKit
import ModelIO
import SwiftData
import JelloCompilerStatic

struct PreviewNodeView: View {
    let node: JelloNode
    let drawBounds: (inout Path) -> ()
    @Environment(\.modelContext) var modelContext
    
    init(node: JelloNode, drawBounds: @escaping (inout Path) -> ()) {
        self.node = node
        self.drawBounds = drawBounds
    }
    
    private func getOutput(nodeData: [JelloNodeData]) -> Data? {
        let nodeId = node.uuid
        var outputDescriptor = FetchDescriptor(predicate: #Predicate<JelloPersistedTextureResource> { $0.originatingStage == nodeId && $0.originatingPass == 1 })
       // outputDescriptor.includePendingChanges = true
        outputDescriptor.sortBy = [SortDescriptor(\JelloPersistedTextureResource.created, order: .reverse)]
        let outputs = try! modelContext.fetch(outputDescriptor)
        let wedgeSha256 = (try! PropertyListEncoder().encode(JelloPreviewGeometry.sphere).sha256())
        let output = outputs.first(where: { $0.wedgeSha256 == wedgeSha256 })
        let texture = output?.texture
        return texture
    }
    
    private func makeImage(imageData: Data) -> UIImage? {
        let ciImage = CIImage(bitmapData: imageData, bytesPerRow: 256*16, size: .init(width: 256, height: 256), format: .RGBAf, colorSpace: nil)
        
        let uiImage = UIImage(ciImage: ciImage)
        return UIImage(data: uiImage.pngData()!)
    }
    
    var body: some View {
        ZStack {
            TimelineView(.animation) { _ in
                let nodeId = node.uuid
                let nodeData = try! modelContext.fetch(FetchDescriptor(predicate: #Predicate<JelloNodeData> { $0.node?.uuid == nodeId }))
                if let tex = getOutput(nodeData: nodeData), let image = makeImage(imageData: tex) {
//                    Path(drawBounds).fill(ImagePaint(image: 
                        Image(uiImage: image)
                        //.resizable()))
                }
            }
            Path(drawBounds).fill(Gradient(colors: [.black.opacity(0.3), .clear]))
            VStack {
                Text("Preview").font(.title2).minimumScaleFactor(0.2)
                    .bold()
                    .monospaced()
                Spacer()
            }.padding(.all, JelloNode.padding)
        }
    }
}
