//
//  FreeEdgesEnvironmentKey.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/17.
//

import Foundation
import SwiftUI

private struct FreeEdgesEnvironmentKey: EnvironmentKey {
    static let defaultValue: [(edge: JelloEdge, dependencies: Set<UUID>)] = []
}


extension EnvironmentValues {
    var freeEdges: [(edge: JelloEdge, dependencies: Set<UUID>)] {
        get { self[FreeEdgesEnvironmentKey.self] }
        set { self[FreeEdgesEnvironmentKey.self] = newValue }
    }
}


extension View {
    func freeEdges(_ value: [(edge: JelloEdge, dependencies: Set<UUID>)]) -> some View {
        environment(\.freeEdges, value)
    }
}
