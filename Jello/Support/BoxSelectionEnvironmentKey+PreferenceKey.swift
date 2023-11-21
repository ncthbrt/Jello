//
//  BoxSelectionEnvironmentKey+Preference.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/21.
//

import Foundation
import SwiftUI

@Observable class BoxSelection {
    var selecting: Bool
    var startPosition: CGPoint
    var endPosition: CGPoint
    var selectedNodes: Set<UUID>
    
    init(selectedNodes: Set<UUID>, selecting: Bool, startPosition: CGPoint, endPosition: CGPoint) {
        self.selectedNodes = selectedNodes
        self.selecting = selecting
        self.startPosition = startPosition
        self.endPosition = endPosition
    }
    
    convenience init(){
        self.init(selectedNodes: [], selecting: false, startPosition: .zero, endPosition: .zero)
    }
    
    func intersects(position: CGPoint, width: CGFloat, height: CGFloat) -> Bool {
        let itemRect = CGRect(origin: CGPoint(x: position.x - width/2, y: position.y - height/2), size: CGSize(width: width, height: height))
        let selectionRect = CGRect(origin: CGPoint(x: min(startPosition.x, endPosition.x), y: min(startPosition.y, endPosition.y)), size: CGSize(width: abs(startPosition.x - endPosition.x), height: abs(startPosition.y - endPosition.y)))
        return selecting && selectionRect.intersects(itemRect)
    }
}


private struct BoxSelectionEnvironmentKey: EnvironmentKey {
    static let defaultValue: BoxSelection = BoxSelection()
}


extension EnvironmentValues {
    var boxSelection: BoxSelection {
        get { self[BoxSelectionEnvironmentKey.self] }
        set { self[BoxSelectionEnvironmentKey.self] = newValue }
    }
}


extension View {
    func boxSelection(_ value: BoxSelection) -> some View {
        environment(\.boxSelection, value)
    }
}

struct BoxSelectionPreferenceKey: PreferenceKey {
  static var defaultValue: Set<UUID> = []
  static func reduce(value: inout Set<UUID>, nextValue: () -> Set<UUID>) {
      value = value.union(nextValue())
  }
}

extension View {
    func setSelection(_ key: UUID, select: Bool) -> some View {
        preference(key: BoxSelectionPreferenceKey.self, value: select ? [key]: [])
    }
    
    func onBoxSelectionChange(_ perform: @escaping (Set<UUID>) -> ()) -> some View{
        onPreferenceChange(BoxSelectionPreferenceKey.self, perform: perform)
    }
}
