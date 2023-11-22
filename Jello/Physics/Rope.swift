//
//  Rioe.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/17.
//

import Foundation
import SwiftUI
import Combine
import simd 

fileprivate protocol Force {
    func apply(v: PositionVertlet, deltaTime: Float, deltaTimeSquared: Float) -> vector_float2
}

fileprivate class ConstantForce: Force {
    let force: vector_float2
    init(force: vector_float2) {
        self.force = force
    }
    
    func apply(v: PositionVertlet, deltaTime: Float, deltaTimeSquared: Float) -> vector_float2 {
        return force
    }
}


fileprivate class LockPositionConstraint : Constraint {
    var v: PositionVertlet
    var p : PositionCell
    var offset : vector_float2
    
    init(v: PositionVertlet, p: PositionCell, offset: vector_float2){
        self.v = v
        self.p = p
        self.offset = offset
    }
    
    convenience init(v: PositionVertlet, p: PositionCell) {
        self.init(v: v, p: p, offset: .zero)
    }
    
    func relaxConstraint() {
        v.position = p.position + offset
    }
}


fileprivate class UnidirectionalDistanceToVertletConstraint : Constraint {
    var target: PositionVertlet
    var v: PositionVertlet
    var targetDistance: DistanceCell
    
    init(target: PositionVertlet, v: PositionVertlet, targetDistance: DistanceCell) {
        self.target = target
        self.v = v
        self.targetDistance = targetDistance
    }
    
    func relaxConstraint() {
        let direction = (target.position - v.position).normal()
        let deltaD = (target.position - v.position).magnitude() - targetDistance.distance
        v.position = v.position + (deltaD * direction)
    }
}

fileprivate class BidirectionalDistanceToVertletConstraint: Constraint {
    var v1: PositionVertlet
    var v2: PositionVertlet
    var targetDistance: DistanceCell
    
    init(v1: PositionVertlet, v2: PositionVertlet, targetDistance: DistanceCell) {
        self.v1 = v1
        self.v2 = v2
        self.targetDistance = targetDistance
    }
    
    func relaxConstraint() {
        let direction = (v2.position - v1.position).normal()
        let deltaD = (v1.position - v2.position).magnitude() - targetDistance.distance
        v1.position = v1.position + (deltaD*direction) * Float(0.5)
        v2.position = v2.position - (deltaD*direction) * Float(0.5)
    }
}



fileprivate class PositionVertlet {
    var acceleration: vector_float2
    var previousPosition: vector_float2
    var position: vector_float2
    var forces: [Force] = []
    var newAcceleration: vector_float2
    
    init(acceleration: vector_float2, position: vector_float2){
        self.acceleration = acceleration
        self.position = position
        self.previousPosition = position
        self.newAcceleration = acceleration
    }
    
    func prepareForces(deltaTime: Float, deltaTimeSquared: Float) {
        newAcceleration = applyForces(deltaTime: deltaTime, deltaTimeSquared: deltaTimeSquared)
    }
   
    func update(deltaTime: Float, deltaTimeSquared: Float){
        let positionCopy: vector_float2 = vector_float2(x: position.x, y: position.y)
        self.position = Float(2.0)*position - previousPosition + deltaTimeSquared*acceleration
        self.previousPosition = positionCopy
    }
    
    func applyForces(deltaTime: Float, deltaTimeSquared: Float) -> vector_float2 {
        return forces.reduce(vector_float2.zero, {result, force in result + force.apply(v: self, deltaTime: deltaTime, deltaTimeSquared: deltaTimeSquared) })
    }
}


class RopeVertletSimulation: ObservableObject, SimulationDrawable {
    static let particleCount = 8
    static let constraintIterations = 4

    private var vertlets: [PositionVertlet] = []
    private var constraints: [Constraint] = []
    private var targetDistanceCell : DistanceCell = DistanceCell(distance: 20)
    private var gravity: vector_float2 = vector_float2(x: 0, y: 200)
    
    @Published var draw: SimulationDrawable.DrawOperation? = nil

    
    var targetDistance: Float {
        get {
            return targetDistanceCell.distance
        }
        
        set {
            targetDistanceCell.distance = newValue
        }
    }
    
    
    private var startPositionCell : PositionCell = PositionCell()
    
    var startPosition: vector_float2 {
        get {
            return startPositionCell.position
        }
        
        set {
            startPositionCell.position = newValue
        }
    }
    
    private var endPositionCell : PositionCell = PositionCell()
    var endPosition: vector_float2 {
        get {
            return endPositionCell.position
        }
        
        set {
            endPositionCell.position = newValue
        }
    }
    
        
    func setup(start: vector_float2, end: vector_float2) {
        constraints = []
        vertlets = []
        self.targetDistance = 20
        let gravitationalForce = ConstantForce(force: gravity)
        
        let startVertlet = PositionVertlet(acceleration: vector_float2(x: 0, y: 200), position: start)
        vertlets.append(startVertlet)
        self.constraints.append(LockPositionConstraint(v: startVertlet, p: startPositionCell))
        
        let endVertlet = PositionVertlet(acceleration: vector_float2(x: 0, y: 200), position: end)
        self.constraints.append(LockPositionConstraint(v: endVertlet, p: endPositionCell))
        

        for i in 1..<(Self.particleCount-1) {
            let position = vector_float2.lerp(a: start, b: end, t: Float(i)  / Float(Self.particleCount))
            let previousVertlet = vertlets.last!;
            let currentVertlet = PositionVertlet(acceleration: vector_float2(x: 0, y: 200), position: position)
            currentVertlet.forces.append(gravitationalForce)
            vertlets.append(currentVertlet)
            
            if (i == 1) {
                constraints.append(UnidirectionalDistanceToVertletConstraint(target: previousVertlet, v: currentVertlet, targetDistance: targetDistanceCell))
            } else if(i < Self.particleCount-2) {
                constraints.append(BidirectionalDistanceToVertletConstraint(v1: previousVertlet, v2: currentVertlet, targetDistance: targetDistanceCell))
            } else {
                constraints.append(BidirectionalDistanceToVertletConstraint(v1: previousVertlet, v2: currentVertlet, targetDistance: targetDistanceCell))
                constraints.append(UnidirectionalDistanceToVertletConstraint(target: endVertlet, v: currentVertlet, targetDistance: targetDistanceCell))
            }
        }
        
        vertlets.append(endVertlet)
    }
    
    func update(dt: Float, dt2: Float) -> SimulationDrawable.DrawOperation {
        targetDistance = Float(min(50, Float(max(0.01, (startPosition - endPosition).magnitude())) * Float(1.1 / max(Float(self.vertlets.count), 2))))
        
        for v in self.vertlets {
            v.prepareForces(deltaTime: dt, deltaTimeSquared: dt2)
        }
        for v in self.vertlets {
            v.update(deltaTime: dt, deltaTimeSquared: dt2)
        }
        
        for _ in 0..<Self.constraintIterations {
            for i in 0..<self.constraints.count {
                self.constraints[i].relaxConstraint()
            }
        }
        let positions = vertlets.map { $0.position }

        return { path in self.drawFunc(positions: positions, path: &path) }
    }
    
    
    func sync(operation: @escaping DrawOperation) {
        draw = operation
    }
    
    
    @Sendable private func drawFunc(positions: [vector_float2], path: inout Path) {
        if let first = positions.first {
            path.move(to: CGPoint(first))
        }
        for p in positions.dropFirst(1) {
            path.addLine(to: CGPoint(p))
        }
    }
   
}
