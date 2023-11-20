//
//  BoxSelectionView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/20.
//

import SwiftUI

struct BoxSelectionView: View {
    let start: CGPoint
    let end: CGPoint
    @Environment(\.canvasTransform) var canvasTransform
    
    var body: some View {
        let width = abs(start.x - end.x)
        let height = abs(start.y - end.y)
        let rect = CGRect(x: min(start.x, end.x) + canvasTransform.position.x + width/2, y: min(start.y, end.y) + canvasTransform.position.y + height/2, width: width, height: height)
        ZStack {
            RoundedRectangle(cornerRadius: 5 / canvasTransform.scale).background(.green).opacity(0.1)
            RoundedRectangle(cornerRadius: 5 / canvasTransform.scale).stroke(lineWidth: 2 / canvasTransform.scale).fill(.green)
        }
        .frame(width: rect.width, height: rect.height)
        .position(rect.origin)
    }
}

