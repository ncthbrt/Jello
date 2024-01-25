//
//  CalculatorView.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2024/01/25.
//

import Foundation
import SwiftUI


enum CalculatorValue {
    case float(Float)
    case int(Int)
}

fileprivate struct MonitorView: View {
    let value: CalculatorValue
    
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10).fill(.thinMaterial)
            HStack(alignment: .bottom) {
                Spacer()
                switch value {
                case .float(let f):
                    Text("\(f)")
                case .int(let i):
                    Text("\(i)")
                }
            }.padding(10).monospaced()
        }
    }
}

struct KeyboardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: .infinity).fill(.thickMaterial).shadow(radius: -4).overlay(content: {
                if configuration.isPressed {
                    RoundedRectangle(cornerRadius: .infinity).fill(.white.opacity(0.2)).shadow(radius: 8)
                }
            }).allowsHitTesting(false)
            configuration.label
                .foregroundStyle(.white)
        }
    }
}



struct KeyboardButton<Label>: View where Label : View {
    @ViewBuilder let label: () -> Label
    let width: Int
    
    var body: some View {
        Button<Label>(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: label).frame(width: CGFloat(width) * 50 + CGFloat((width - 1) * 10), height: 50).buttonStyle(KeyboardButtonStyle()).zIndex(-1)
    }
    
}

fileprivate struct KeyboardView: View {
    @State var currentSelectedOverlay : Int? = nil
    
    var body: some View {
        VStack(alignment: .center, spacing: 10){
            HStack(spacing: 10) {
                KeyboardButton(label: {Text("7")}, width: 1)
                KeyboardButton(label: {Text("8")}, width: 1)
                KeyboardButton(label: {Text("9")}, width: 1)
                KeyboardButton(label: {Image(systemName: "trash")}, width: 1)
                KeyboardButton(label: {Image(systemName: "delete.backward")}, width: 1)
            }
            HStack(spacing: 10) {
                KeyboardButton(label: {Text("4")}, width: 1)
                KeyboardButton(label: {Text("5")}, width: 1)
                KeyboardButton(label: {Text("6")}, width: 1)
                KeyboardButton(label: {Image(systemName: "multiply")}, width: 1)
                KeyboardButton(label: {Image(systemName: "divide")}, width: 1)
            }
            HStack(spacing: 10) {
                KeyboardButton(label: {Text("1")}, width: 1)
                KeyboardButton(label: {Text("2")}, width: 1)
                KeyboardButton(label: {Text("3")}, width: 1)
                KeyboardButton(label: {Image(systemName: "plus")}, width: 1)
                KeyboardButton(label: {Image(systemName: "minus")}, width: 1)
            }
            HStack(spacing: 10) {
                KeyboardButton(label: {Text("0")}, width: 2)
                RadialMenu(label: { Text("()").monospaced()}, entries: [")", "("], entryBuilder: {
                    entry in Text(entry)
                }, onSelection: { entry in
                }, onOpen: { currentSelectedOverlay = 0 }, onClose: { currentSelectedOverlay = nil }).zIndex(currentSelectedOverlay == 0 ? 100 : 0)
                RadialMenu(label: { Image(systemName: "function")}, entries: ["sin", "cos", "tan", "sqrt"], entryBuilder: {
                    entry in Text(entry)
                }, onSelection: { entry in
                }, onOpen: { currentSelectedOverlay = 1 }, onClose: { currentSelectedOverlay = nil }).zIndex(currentSelectedOverlay == 1 ? 99 : 0)
                KeyboardButton(label: {Image(systemName:"equal")}, width: 1)
            }
        }
    }
}

struct CalculatorView: View {
    @Binding var value: CalculatorValue
    
    
    var body: some View {
        VStack(spacing: 30) {
            MonitorView(value: value).frame(height: 50)
            KeyboardView()
        }
    }
}


#Preview {
    VStack {
        CalculatorView(value: .constant(.int(123))).frame(width: 300, height: 500)
    }
}
