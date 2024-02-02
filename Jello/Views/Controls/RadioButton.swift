//
//  RadioButton.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/02/01.
//

import Foundation
import SwiftUI



struct JelloRadioButton<Label> : View where Label: View {
    let fill: Gradient
    let selected: Bool
    @ViewBuilder let label: () -> Label
    let onSelected: () -> ()
    @Environment(\.isEnabled) var isEnabled

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Rectangle().fill(.ultraThickMaterial)
                RectAnimatedShape(frac: selected ? 1 : 0).fill(fill)
            }.frame(width: 15, height: 15)
            label()
        }.onTapGesture {
            if isEnabled {
                onSelected()
            }
        }.opacity(isEnabled ? 1: 0.4)
    }
}

struct JelloRadioButtonHGroup<Label, Entry> : View  where Label: View, Entry: Identifiable & Equatable {
    let entries: [Entry]
    @Binding var currentSelection: Entry
    @ViewBuilder let label: (Entry) -> Label
    @ViewBuilder let fill: (Entry) -> Gradient

    
    var body: some View {
        HStack(spacing: 15) {
            ForEach(entries) { entry in
                JelloRadioButton(fill: fill(entry), selected: currentSelection == entry, label: { label(entry) }, onSelected: { currentSelection = entry })
            }
        }.animation(.spring.speed(2), value: currentSelection)
    }
}

