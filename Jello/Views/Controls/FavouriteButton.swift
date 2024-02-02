//
//  FavouriteButton.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/02/02.
//

import Foundation
import SwiftUI


fileprivate struct FavouriteButtonStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            configuration.label.foregroundStyle(.gray).opacity(0.4)
            configuration.label.clipShape(RectAnimatedShape(frac: configuration.isOn ? 1: 0)).foregroundStyle(Gradient(colors: [.yellow, .orange]))
        }.contentShape(Rectangle()).onTapGesture {
            configuration.isOn.toggle()
        }.animation(.bouncy.speed(2), value: configuration.isOn)
    }
}

struct FavouriteButton: View {
    @Binding var isFavourite: Bool

    var body: some View {
        Toggle(isOn: $isFavourite) {
            Image(systemName: "star.fill").resizable().aspectRatio(contentMode: .fit)
        }.toggleStyle(FavouriteButtonStyle()).padding(8)
    }
}
