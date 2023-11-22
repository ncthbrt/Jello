//
//  Vertlet.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/06.
//

import Foundation
import SwiftUI
import simd

fileprivate protocol Force {
    func apply(v: VelocityVertlet, deltaTime: Float, deltaTimeSquared: Float) -> vector_float2
}

fileprivate class ConstantForce: Force {
    let force: vector_float2
    init(force: vector_float2) {
        self.force = force
    }
    
    func apply(v: VelocityVertlet, deltaTime: Float, deltaTimeSquared: Float) -> vector_float2 {
        return force
    }
}


fileprivate class DamperForce: Force {
    let coefficient: Float
    init(coefficient: Float) {
        self.coefficient = coefficient
    }
    
    func apply(v: VelocityVertlet, deltaTime: Float, deltaTimeSquared: Float) -> vector_float2 {
        return -coefficient * v.velocity
    }
}


fileprivate class SpringForce: Force {
    let coefficient: Float
    let target: VelocityVertlet
    let distance: Float
    var targetOffset: vector_float2
    
    init(coefficient: Float, target: VelocityVertlet, distance: Float, targetOffset: vector_float2 = .zero) {
        self.coefficient = coefficient
        self.target = target
        self.distance = distance
        self.targetOffset = targetOffset
    }
    
    func apply(v: VelocityVertlet, deltaTime: Float, deltaTimeSquared: Float) -> vector_float2 {
        let delta = target.position + targetOffset - v.position
        return -coefficient * (distance - delta.magnitude()) * (delta.normal())
    }
}


fileprivate class InteractionDraggingConstraint: Constraint {
    let position: PositionCell
    let dragPoint: PositionCell
    let falloff: Float
    var targetOffset: vector_float2
    let onOff: OnOffCell
    let v: VelocityVertlet
    
    init(v: VelocityVertlet, position: PositionCell, dragPoint: PositionCell, targetOffset: vector_float2 = .zero, falloff: Float, onOff: OnOffCell) {
        self.v = v
        self.targetOffset = targetOffset
        self.position = position
        self.dragPoint = dragPoint
        self.falloff = falloff
        self.onOff = onOff
    }
    
    
    func relaxConstraint() {
        if onOff.on {
            let dragDelta = v.position - dragPoint.position
            let magSquared = max(dragDelta.magnitudeSquared(), 0.001)
            let weight = Float(max(min(falloff / magSquared, 2), 0))
            v.position = vector_float2.lerp(a: v.position, b: position.position + targetOffset, t: weight)
        }
    }
}

fileprivate class VelocityVertlet {
    var acceleration: vector_float2
    var position: vector_float2
    var velocity: vector_float2
    var forces: [Force] = []
    var newAcceleration: vector_float2
    
    init(acceleration: vector_float2, position: vector_float2, velocity: vector_float2){
        self.acceleration = acceleration
        self.position = position
        self.velocity = velocity
        self.newAcceleration = acceleration
    }
    
    func prepareForces(deltaTime: Float, deltaTimeSquared: Float) {
        newAcceleration = applyForces(deltaTime: deltaTime, deltaTimeSquared: deltaTimeSquared)
    }
    
    func update(deltaTime: Float, deltaTimeSquared: Float){
        let newPosition = position + velocity*deltaTime + acceleration*(deltaTimeSquared*0.5);
        let newVelocity = velocity + (acceleration+newAcceleration)*(deltaTime*0.5)
        position = newPosition
        velocity = newVelocity
        acceleration = newAcceleration
    }
    
    func applyForces(deltaTime: Float, deltaTimeSquared: Float) -> vector_float2 {
        return forces.reduce(vector_float2.zero, {result, force in result + force.apply(v: self, deltaTime: deltaTime, deltaTimeSquared: deltaTimeSquared) })
    }
}

fileprivate class LockPositionConstraint : Constraint {
    var v: VelocityVertlet
    var p : PositionCell
    var offset : vector_float2
    
    init(v: VelocityVertlet, p: PositionCell, offset: vector_float2){
        self.v = v
        self.p = p
        self.offset = offset
    }
    
    convenience init(v: VelocityVertlet, p: PositionCell) {
        self.init(v: v, p: p, offset: .zero)
    }
    
    func relaxConstraint() {
        v.position = p.position + offset
    }
}


class JellyBoxVertletSimulation: ObservableObject, SimulationDrawable {
    private var top: [VelocityVertlet] = []
    private var bottom: [VelocityVertlet] = []
    private var left: [VelocityVertlet] = []
    private var right: [VelocityVertlet] = []
    
    private var topConstraints: [InteractionDraggingConstraint] = []
    private var bottomConstraints: [InteractionDraggingConstraint] = []
    private var leftConstraints: [InteractionDraggingConstraint] = []
    private var rightConstraints: [InteractionDraggingConstraint] = []
    
    private var isSetup: Bool = false
    private var vertlets: [VelocityVertlet] = []
    private var constraints: [Constraint] = []
    @Published var draw: SimulationDrawable.DrawOperation? = nil
    
    var radius : Float = 5
    var dimensions : vector_float2 = .zero {
        didSet {
            if isSetup {
                update()
            }
        }
    }
    
    let xCount = 4
    let yCount = 4
    
    var draggingCell: OnOffCell = OnOffCell()
    var dragging : Bool {
        get { draggingCell.on }
        set { draggingCell.on = newValue }
    }

    var updateIterations: Int = 4
    var constraintIterations: Int = 4
    var simulationTask: Task<Void, Error>? = nil
    
    var topLeftCell: PositionCell = PositionCell()
    var position: vector_float2 {
        get { topLeftCell.position}
        set {
            topLeftCell.position = newValue
        }
    }
    
    var dragPositionCell: PositionCell = PositionCell()
    var dragPosition: vector_float2 {
        get { dragPositionCell.position }
        set { dragPositionCell.position = newValue }
    }
    
    func setup(dimensions: vector_float2, topLeft: vector_float2, constraintIterations: Int, updateIterations: Int, radius: Float) {
        constraints = []
        vertlets = []
        self.dimensions = dimensions
        self.position = topLeft
        self.radius = Float(radius)
        self.dragPosition = topLeft
        self.updateIterations = updateIterations
        self.constraintIterations = constraintIterations
        
        
        let xStride = vector_float2(x: dimensions.x / Float(xCount), y: 0)
        let yStride = vector_float2(x: 0, y: dimensions.y / Float(yCount))
                
        let dampingForce = DamperForce(coefficient: 6)
        
        top = []
        bottom = []
        left = []
        right = []
        topConstraints = []
        bottomConstraints = []
        leftConstraints = []
        rightConstraints = []
        
        let anchorVertlet = VelocityVertlet(acceleration: .zero, position: topLeft, velocity: .zero)
        vertlets.append(anchorVertlet)
        constraints.append(LockPositionConstraint(v: anchorVertlet, p: topLeftCell))
        
        for i in 0...xCount {
            let offset = xStride * Float(i)
            let initialPosition = topLeft + offset
            let vertlet = VelocityVertlet(acceleration: .zero, position: initialPosition, velocity: .zero)
            top.append(vertlet)
            vertlet.forces.append(dampingForce)
            let constraint = InteractionDraggingConstraint(v: vertlet, position: topLeftCell, dragPoint: dragPositionCell, targetOffset: offset, falloff: 200, onOff: draggingCell)
            constraints.append(constraint)
            topConstraints.append(constraint)
            vertlet.forces.append(SpringForce(coefficient: 75, target: anchorVertlet, distance: 0, targetOffset: offset))
            vertlets.append(vertlet)
        }
        
        for i in (0...xCount).reversed() {
            let offset = xStride * Float(i) + dimensions * vector_float2(x: 0, y: 1)
            let initialPosition = topLeft + offset
            let vertlet = VelocityVertlet(acceleration: .zero, position: initialPosition, velocity: .zero)
            bottom.append(vertlet)
            vertlet.forces.append(dampingForce)
            let constraint = InteractionDraggingConstraint(v: vertlet, position: topLeftCell, dragPoint: dragPositionCell, targetOffset: offset, falloff: 200, onOff: draggingCell)
            constraints.append(constraint)
            bottomConstraints.append(constraint)
            vertlet.forces.append(SpringForce(coefficient: 75, target: anchorVertlet, distance: 0, targetOffset: offset))
            vertlets.append(vertlet)
        }
        
        for i in (1..<yCount).reversed() {
            let offset = yStride * Float(i)
            let initialPosition = topLeft + offset
            let vertlet = VelocityVertlet(acceleration: .zero, position: initialPosition, velocity: .zero)
            left.append(vertlet)
            vertlet.forces.append(dampingForce)
            let constraint = InteractionDraggingConstraint(v: vertlet, position: topLeftCell, dragPoint: dragPositionCell, targetOffset: offset, falloff: 200, onOff: draggingCell)
            constraints.append(constraint)
            leftConstraints.append(constraint)
            vertlet.forces.append(SpringForce(coefficient: 75, target: anchorVertlet, distance: 0, targetOffset: offset))
            vertlets.append(vertlet)
        }
        
        for i in (1..<yCount) {
            let offset = yStride * Float(i) + dimensions * vector_float2(x: 1, y: 0)
            let initialPosition = topLeft + offset
            let vertlet = VelocityVertlet(acceleration: .zero, position: initialPosition, velocity: .zero)
            right.append(vertlet)
            vertlet.forces.append(dampingForce)
            let constraint = InteractionDraggingConstraint(v: vertlet, position: topLeftCell, dragPoint: dragPositionCell, targetOffset: offset, falloff: 200, onOff: draggingCell)
            constraints.append(constraint)
            rightConstraints.append(constraint)
            vertlet.forces.append(SpringForce(coefficient: 75, target: anchorVertlet, distance: 0, targetOffset: offset))
            vertlets.append(vertlet)
        }
        
        isSetup = true

    }
    
    func update() {
        let xStride = vector_float2(x: dimensions.x / Float(xCount), y: 0)
        let yStride = vector_float2(x: 0, y: dimensions.y / Float(yCount))
        
        for i in 0...xCount {
            let offset = xStride * Float(i)
            let vertlet = top[i]
            let springForces = vertlet.forces.map{ force in force as? SpringForce }.filter {
                force in force != nil
            }
            for springForce in springForces {
                springForce!.targetOffset = offset
            }
            
            
            let constraint = topConstraints[i]
            constraint.targetOffset = offset
        }
        
        for i in (0...xCount) {
            let offset = xStride * Float(i) + dimensions * vector_float2(x: 0, y: 1)
            let vertlet = bottom[bottom.count-1-i]
            let springForces = vertlet.forces.map{ force in force as? SpringForce }.filter {
                force in force != nil
            }
            for springForce in springForces {
                springForce!.targetOffset = offset
            }
            
            let constraint = bottomConstraints[bottomConstraints.count-1-i]
            constraint.targetOffset = offset
            
        }
        
        
        for i in (1..<yCount) {
            let offset = yStride * Float(i)
            let vertlet = left[left.count-i]
            let springForces = vertlet.forces.map{ force in force as? SpringForce }.filter {
                force in force != nil
            }
            for springForce in springForces {
                springForce!.targetOffset = offset
            }
            
            let constraint = leftConstraints[leftConstraints.count-i]
            constraint.targetOffset = offset
        }
        
        for i in (1..<yCount) {
            let offset = yStride * Float(i) + dimensions * vector_float2(x: 1, y: 0)
            let vertlet = right[i-1]
            let springForces = vertlet.forces.map{ force in force as? SpringForce }.filter {
                force in force != nil
            }
            for springForce in springForces {
                springForce!.targetOffset = offset
            }
            let constraint = rightConstraints[i-1]
            constraint.targetOffset = offset
        }
    }
    
    @Sendable func update(dt: Float, dt2: Float) -> SimulationDrawable.DrawOperation {
        for _ in 0..<updateIterations {
            for v in self.vertlets {
                v.prepareForces(deltaTime: dt, deltaTimeSquared: dt2)
            }
            for v in self.vertlets {
                v.update(deltaTime: dt, deltaTimeSquared: dt2)
            }
        }
        for _ in 0..<constraintIterations {
            for i in 0..<self.constraints.count {
                self.constraints[i].relaxConstraint()
            }
        }
        
        let top = top.map { $0.position }
        let right = right.map { $0.position }
        let left = left.map { $0.position }
        let bottom = bottom.map { $0.position }
        let position = self.position
        return { path in self.draw(path: &path, top: top, left: left, right: right, bottom: bottom, position: position) }
    }
        
    private func drawCorner(path: inout Path, z: vector_float2, a: vector_float2, b: vector_float2, c: vector_float2, position: vector_float2) {
        let deltaAB = b - a
        let deltaCB = c - b
        
        let p1 = b - deltaAB.normal() * radius
        let p2 = b + deltaCB.normal() * radius
        path.addCurve(to: CGPoint(p1 - position), control1: CGPoint(z-position), control2: CGPoint(a-position))
        path.addQuadCurve(to: CGPoint(p2 - position), control: CGPoint(b  - position))
    }
    
    @Sendable func draw(path: inout Path, top: [vector_float2], left: [vector_float2], right: [vector_float2], bottom: [vector_float2], position: vector_float2){
        if top.count > 0 && right.count > 0 {
            let startPoint = top[0] + (top[1] - top[0]).normal() * radius - position
            path.move(to: CGPoint(startPoint))
            
            drawCorner(path: &path, z: top[top.count-3], a: top[top.count-2], b: top[top.count-1], c: right[0], position: position)
                        
            drawCorner(path: &path, z: right[right.count-2], a: right[right.count-1], b: bottom[0], c: bottom[1], position: position)

            drawCorner(path: &path, z: bottom[bottom.count-3], a: bottom[bottom.count-2], b: bottom[bottom.count-1], c: left[0], position: position)
            
            drawCorner(path: &path, z: left[left.count-2], a: left[left.count-1], b: top[0], c: top[1], position: position)
            path.closeSubpath()
        }
    }
    
    func sync(operation: @escaping DrawOperation) {
        draw = operation
    }
   
}
