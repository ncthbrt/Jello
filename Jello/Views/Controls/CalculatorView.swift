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
    let value: [String]
    @Binding var insertionPoint: Int
    @State var showCaret: Bool = true
    var body: some View {
        ZStack(alignment: .init(horizontal: .trailing, vertical: .center)) {
            RoundedRectangle(cornerRadius: 10).fill(.thinMaterial)
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach((0..<value.count).reversed(), id: \.self) { i in
                        Text(value[i]).contentShape(Rectangle()).highPriorityGesture(SpatialTapGesture().onEnded { event in
                            if event.location.x >= 0 {
                                insertionPoint = i + 1
                            } else {
                                insertionPoint = i
                            }
                        })
                        .font(.system(size: 24)).monospaced().overlay(content: {
                            if i + 1 == insertionPoint {
                                HStack {
                                    TimelineView(.periodic(from: .distantPast, by: 0.5)) { context in
                                        Rectangle().fill(.white).frame(width: 2, height: 24).opacity((Calendar.current.component(.nanosecond, from: context.date) / 500000000) % 2 == 0 ? 1: 0).padding(.vertical, 10)
                                    }
                                    Spacer()
                                }
                            }
                        })
                    }
                    if insertionPoint == 0 {
                        TimelineView(.periodic(from: .distantPast, by: 0.5)) { context in
                            Rectangle().fill(.white).frame(width: 2, height: 24).opacity((Calendar.current.component(.nanosecond, from: context.date) / 500000000) % 2 == 0 ? 1: 0)
                        }
                    }
                }.monospaced().foregroundStyle(.white).padding(10)
            }.scrollIndicators(.hidden).defaultScrollAnchor(.trailing)
        }.gesture(TapGesture().onEnded { insertionPoint = 0 }).environment(\.layoutDirection, .rightToLeft)

    }
}

fileprivate struct StatusView: View {
    let valid: Bool
    
    var body: some View {
        HStack {
            Spacer()
            Text(valid ? "VALID" : "ERROR").monospaced().font(.subheadline).foregroundStyle(valid ? .green : .red)
            Circle().fill(valid ? .green : .red)
        }.frame(height: 15).padding(.horizontal, 10)
    }
}

fileprivate struct KeyboardButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            if configuration.role != .destructive {
                RoundedRectangle(cornerRadius: .infinity).fill(.ultraThinMaterial).shadow(radius: -4).overlay(content: {
                    if configuration.isPressed {
                        RoundedRectangle(cornerRadius: .infinity).fill(.white.opacity(0.2))
                    }
                })
            } else {
                RoundedRectangle(cornerRadius: .infinity).fill(.red).shadow(radius: -4).overlay(content: {
                    if configuration.isPressed {
                        RoundedRectangle(cornerRadius: .infinity).fill(.white.opacity(0.2)).shadow(radius: 8)
                    }
                })
            }
            configuration.label
                .foregroundStyle(.white)
        }
    }
}




struct KeyboardButton<Label>: View where Label : View {
    @ViewBuilder let label: () -> Label
    let width: Int
    let role : ButtonRole?
    let onClick : () -> ()
    
    var body: some View {
        if let r = role {
            Button<Label>(role: r, action: onClick, label: label).frame(width: CGFloat(width) * 50 + CGFloat((width - 1) * 10), height: 50).buttonStyle(KeyboardButtonStyle()).zIndex(-1)
        } else {
            Button<Label>(action: onClick, label: label).frame(width: CGFloat(width) * 50 + CGFloat((width - 1) * 10), height: 50).buttonStyle(KeyboardButtonStyle()).zIndex(-1)
        }
    }
    
    init(label: @escaping () -> Label, width: Int, role: ButtonRole?, onClick: @escaping () -> ()) {
        self.label = label
        self.width = width
        self.role = role
        self.onClick = onClick
    }
    
    init(label:  @escaping () -> Label, width: Int, onClick: @escaping () -> ()) {
        self.init(label: label, width: width, role: nil, onClick: onClick)
    }
    
    init(label:  @escaping () -> Label, onClick: @escaping () -> ()) {
        self.init(label: label, width: 1, role: nil, onClick: onClick)
    }
}

fileprivate struct KeyboardView: View {
    @State var currentSelectedOverlay : Int? = nil
    @Binding var value: [String]
    @Binding var insertionPoint: Int
    let valid: Bool
    
    func appendString(_ str: String) {
        var v = value
        v.insert(str, at: insertionPoint)
        value = v
        insertionPoint = insertionPoint + 1
    }
    
    func clear(){
        value = []
        insertionPoint = 0
    }
    
    func backspace() {
        var v = value
        v.remove(at: insertionPoint - 1)
        value = v
        insertionPoint = max(0, insertionPoint - 1)
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 10){
            let backspaceDisabled = value.count == 0 || insertionPoint == 0
            HStack(spacing: 10) {
                KeyboardButton(label: {Text("7")}, onClick: {appendString("7")})
                KeyboardButton(label: {Text("8")}, onClick: {appendString("8")})
                KeyboardButton(label: {Text("9")}, onClick: {appendString("9")})
                KeyboardButton(label: {Image(systemName: "trash")}, width: 1, role: .destructive, onClick: {clear()})
                KeyboardButton(label: {Image(systemName: "delete.backward")}, width: 1, role: .destructive, onClick: {backspace()}).disabled(backspaceDisabled).opacity(backspaceDisabled ? 0.5 : 1)
            }
            HStack(spacing: 10) {
                KeyboardButton(label: {Text("4")}, onClick: {appendString("4")})
                KeyboardButton(label: {Text("5")}, onClick: {appendString("5")})
                KeyboardButton(label: {Text("6")}, onClick: {appendString("6")})
                RadialMenu(label: {
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            Image(systemName: "plus")
                            Image(systemName: "multiply")
                        }
                        HStack(spacing: 0) {
                            Image(systemName: "minus")
                            Image(systemName: "divide")
                        }
                    }.font(.footnote)
                }, entries: ["plus", "minus", "divide", "multiply", "power"], entryBuilder: {
                    entry in
                    if entry != "power" {
                        Image(systemName: entry)
                    } else {
                        Text("^")
                    }
                }, onSelection: { entry in
                    if entry == "plus" {
                        appendString("+")
                    } else if entry == "minus" {
                        appendString("-")
                    } else if entry == "divide" {
                        appendString("/")
                    }
                    else {
                        appendString("*")
                    }
                }, onOpen: { currentSelectedOverlay = 0 }, onClose: { currentSelectedOverlay = nil }).zIndex(currentSelectedOverlay == 0 ? 100 : 0)
                RadialMenu(label: { Image(systemName: "function")}, entries: ["sqrt", "round", "floor", "ceil", "abs", "log"], entryBuilder: {
                    entry in Text(entry)
                }, onSelection: { entry in
                    appendString("\(entry)(")
                }, onOpen: { currentSelectedOverlay = 1 }, onClose: { currentSelectedOverlay = nil }).zIndex(currentSelectedOverlay == 1 ? 100 : 0)
            }.zIndex(currentSelectedOverlay == 0 || currentSelectedOverlay == 1 ? 100 : 0)
            HStack(spacing: 10) {
                KeyboardButton(label: {Text("1")}, onClick: { appendString("1") })
                KeyboardButton(label: {Text("2")}, onClick: { appendString("2") })
                KeyboardButton(label: {Text("3")}, onClick: { appendString("3") })
                RadialMenu(label: { Text("xy").italic() }, entries: ["x", "y", "z", "w"], entryBuilder: {
                    entry in Text(entry)
                }, onSelection: { entry in appendString(entry) }, onOpen: { currentSelectedOverlay = 2 }, onClose: { currentSelectedOverlay = nil }).zIndex(currentSelectedOverlay == 2 ? 100 : 0)
                RadialMenu(label: { Text("π").italic() }, entries: ["pi", "e", "tau", "phi"], entryBuilder: {
                    entry in Text(entry)
                }, onSelection: { entry in appendString(entry)
                }, onOpen: { currentSelectedOverlay = 3 }, onClose: { currentSelectedOverlay = nil }).zIndex(currentSelectedOverlay == 3 ? 100 : 0)
            }.zIndex(currentSelectedOverlay == 2 || currentSelectedOverlay == 3 ? 100 : 0)
            HStack(spacing: 10) {
                KeyboardButton(label: {Text(".")}, onClick: {appendString(".")})
                KeyboardButton(label: {Text("0")}, onClick: {appendString("0")})
                KeyboardButton(label: {Text("(").monospaced()}, onClick: {appendString("(")})
                KeyboardButton(label: {Text(")").monospaced()}, onClick: {appendString(")")})
                RadialMenu(label: { Image(systemName: "angle")}, entries: ["sin", "cos", "tan", "atan", "acos", "asin"], entryBuilder: {
                    entry in Text(entry)
                }, onSelection: { entry in appendString("\(entry)(")
                }, onOpen: { currentSelectedOverlay = 5 }, onClose: { currentSelectedOverlay = nil }).zIndex(currentSelectedOverlay == 5 ? 99 : 0)
            }
        }
    }
}

struct CalculatorView: View {
    @Binding var value: [String]
    @State var insertionPoint: Int = 0
    let valid : Bool
    
    var body: some View {
        VStack(spacing: 30) {
            MonitorView(value: value, insertionPoint: $insertionPoint).frame(height: 50)
            KeyboardView(value: $value, insertionPoint: $insertionPoint, valid: valid)
            StatusView(valid: valid).zIndex(-1)
        }.animation(.spring, value: valid)
    }
}


struct CalculatorPreviewView: View {
    @State var value: [String] = []
    @State var insertionPoint: Int = 0
    @State var valid : Bool = false
    
    var body: some View {
        CalculatorView(value: $value, valid: valid)
    }
}


#Preview {
    VStack {
        CalculatorPreviewView().frame(width: 300, height: 360)
    }
}
