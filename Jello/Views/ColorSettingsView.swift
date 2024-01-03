//
//  ColorSettingsView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/01.
//

import SwiftUI
import UIKit

struct ColorSettingsView: View {
    @State private var color =
        Color(.sRGB, red: 0.98, green: 0.9, blue: 0.2)

    var body: some View {
        VStack(alignment: .leading) {
            Button("Frog", action: {
                    let colorPicker = UIColorPickerViewController()
                   colorPicker.title = "Background Color"
                   colorPicker.supportsAlpha = false
//                   colorPicker.delegate = self
                   colorPicker.modalPresentationStyle = .popover
//                   colorPicker.popoverPresentationController?.sourceItem = self.navigationItem.rightBarButtonItem
                   self.present(colorPicker, animated: true)
            })
        }
    }
}

#Preview {
    ColorSettingsView()
}
