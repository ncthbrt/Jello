//
//  Vertlet.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/06.
//

import Foundation
import SwiftUI

fileprivate protocol Force {
    func apply(v: VelocityVertlet, deltaTime: CGFloat, deltaTimeSquared: CGFloat) -> CGPoint
}

fileprivate class ConstantForce: Force {
    let force: CGPoint
    init(force: CGPoint) {
        self.force = force
    }
    
    func apply(v: VelocityVertlet, deltaTime: CGFloat, deltaTimeSquared: CGFloat) -> CGPoint {
        return force
    }
}


fileprivate class DamperForce: Force {
    let coefficient: CGFloat
    init(coefficient: CGFloat) {
        self.coefficient = coefficient
    }
    
    func apply(v: VelocityVertlet, deltaTime: CGFloat, deltaTimeSquared: CGFloat) -> CGPoint {
        return -coefficient * v.velocity
    }
}


fileprivate class SpringForce: Force {
    let coefficient: CGFloat
    let target: VelocityVertlet
    let distance: CGFloat
    var targetOffset: CGPoint
    
    init(coefficient: CGFloat, target: VelocityVertlet, distance: CGFloat, targetOffset: CGPoint = .zero) {
        self.coefficient = coefficient
        self.target = target
        self.distance = distance
        self.targetOffset = targetOffset
    }
    
    func apply(v: VelocityVertlet, deltaTime: CGFloat, deltaTimeSquared: CGFloat) -> CGPoint {
        let delta = target.position + targetOffset - v.position
        return -coefficient * (distance - delta.magnitude()) * (delta.normal())
    }
}


fileprivate class InteractionDraggingConstraint: Constraint {
    let position: PositionCell
    let dragPoint: PositionCell
    let falloff: CGFloat
    var targetOffset: CGPoint
    let onOff: OnOffCell
    let v: VelocityVertlet
    
    init(v: VelocityVertlet, position: PositionCell, dragPoint: PositionCell, targetOffset: CGPoint = .zero, falloff: CGFloat, onOff: OnOffCell) {
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
            v.position = CGPoint.lerp(a: v.position, b: position.position + targetOffset, t: weight)
        }
    }
}

fileprivate class VelocityVertlet {
    var acceleration: CGPoint
    var position: CGPoint
    var velocity: CGPoint
    var forces: [Force] = []
    var newAcceleration: CGPoint
    
    init(acceleration: CGPoint, position: CGPoint, velocity: CGPoint){
        self.acceleration = acceleration
        self.position = position
        self.velocity = velocity
        self.newAcceleration = acceleration
    }
    
    func prepareForces(deltaTime: CGFloat, deltaTimeSquared: CGFloat) {
        newAcceleration = applyForces(deltaTime: deltaTime, deltaTimeSquared: deltaTimeSquared)
    }
    
    func update(deltaTime: CGFloat, deltaTimeSquared: CGFloat){
        let newPosition = position + velocity*deltaTime + acceleration*(deltaTimeSquared*0.5);
        let newVelocity = velocity + (acceleration+newAcceleration)*(deltaTime*0.5)
        position = newPosition
        velocity = newVelocity
        acceleration = newAcceleration
    }
    
    func applyForces(deltaTime: CGFloat, deltaTimeSquared: CGFloat) -> CGPoint {
        return forces.reduce(CGPoint.zero, {result, force in result + force.apply(v: self, deltaTime: deltaTime, deltaTimeSquared: deltaTimeSquared) })
    }
}

fileprivate class LockPositionConstraint : Constraint {
    var v: VelocityVertlet
    var p : PositionCell
    var offset : CGPoint
    
    init(v: VelocityVertlet, p: PositionCell, offset: CGPoint){
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


class JellyBoxVertletSimulation: ObservableObject {
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
    
    var radius : CGFloat = 5
    var dimensions : CGPoint = .zero {
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

    var updateIterations: Int = 5
    var constraintIterations: Int = 20
    var simulationTask: Task<Void, Error>? = nil
    
    var topLeftCell: PositionCell = PositionCell()
    var position: CGPoint {
        get { topLeftCell.position}
        set {
            topLeftCell.position = newValue
        }
    }
    
    var dragPositionCell: PositionCell = PositionCell()
    var dragPosition: CGPoint {
        get { dragPositionCell.position }
        set { dragPositionCell.position = newValue }
    }
    
    func setup(dimensions: CGPoint, topLeft: CGPoint, constraintIterations: Int, updateIterations: Int, radius: CGFloat) {
        constraints = []
        vertlets = []
        self.dimensions = dimensions
        self.position = topLeft
        self.radius = CGFloat(radius)
        self.dragPosition = topLeft
        self.updateIterations = updateIterations
        self.constraintIterations = constraintIterations
        
        
        let xStride = CGPoint(x: dimensions.x / CGFloat(xCount), y: 0)
        let yStride = CGPoint(x: 0, y: dimensions.y / CGFloat(yCount))
                
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
            let offset = xStride * CGFloat(i)
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
            let offset = xStride * CGFloat(i) + dimensions * CGPoint(x: 0, y: 1)
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
            let offset = yStride * CGFloat(i)
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
            let offset = yStride * CGFloat(i) + dimensions * CGPoint(x: 1, y: 0)
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
        let xStride = CGPoint(x: dimensions.x / CGFloat(xCount), y: 0)
        let yStride = CGPoint(x: 0, y: dimensions.y / CGFloat(yCount))
        
        for i in 0...xCount {
            let offset = xStride * CGFloat(i)
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
            let offset = xStride * CGFloat(i) + dimensions * CGPoint(x: 0, y: 1)
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
            let offset = yStride * CGFloat(i)
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
            let offset = yStride * CGFloat(i) + dimensions * CGPoint(x: 1, y: 0)
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
    
    @Sendable private func loop() async throws {
        let clock = SuspendingClock()
        var previousTime = clock.now
        while(true) {
            let currentTime = clock.now
            let deltaTime = currentTime - previousTime
            previousTime = currentTime
            
            let dtDouble: Double = Double(deltaTime.components.attoseconds) * 1.0e-18 / Double(updateIterations)
            let dt = CGFloat(dtDouble)
            let dt2 = CGFloat(dtDouble * dtDouble)
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
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
            try Task.checkCancellation()
            try await Task.sleep(for: Duration.milliseconds(8))
        }
    }
    
    func startUpdate(){
        self.simulationTask = Task.detached(priority: .medium, operation: self.loop)
    }
    
    
    func stopUpdate() {
        if let task = self.simulationTask {
            task.cancel()
        }
    }
        
    private func drawCorner(path: inout Path, z: CGPoint, a: CGPoint, b: CGPoint, c: CGPoint) {
        let deltaAB = b - a
        let deltaCB = c - b
        
        let p1 = b - deltaAB.normal() * radius
        let p2 = b + deltaCB.normal() * radius
        path.addCurve(to: p1 - position, control1: z-position, control2: a-position)
        path.addQuadCurve(to: p2 - position, control: b  - position)
    }
    
    func draw(path: inout Path){
        if top.count > 0 && right.count > 0 {
            let startPoint = top[0].position + (top[1].position - top[0].position).normal() * radius - position
            path.move(to: startPoint)
            
            drawCorner(path: &path, z: top[top.count-3].position, a: top[top.count-2].position, b: top[top.count-1].position, c: right[0].position)
                        
            drawCorner(path: &path, z: right[right.count-2].position, a: right[right.count-1].position, b: bottom[0].position, c: bottom[1].position)

            drawCorner(path: &path, z: bottom[bottom.count-3].position, a: bottom[bottom.count-2].position, b: bottom[bottom.count-1].position, c: left[0].position)
            
            drawCorner(path: &path, z: left[left.count-2].position, a: left[left.count-1].position, b: top[0].position, c: top[1].position)
            path.closeSubpath()
        }
    }
   
}
