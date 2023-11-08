//
//  Vertlet.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/06.
//

import Foundation


protocol Force {
    func apply(v: Vertlet, deltaTime: CGFloat, deltaTimeSquared: CGFloat) -> CGPoint
}

class ConstantForce: Force {
    let force: CGPoint
    init(force: CGPoint) {
        self.force = force
    }
    
    func apply(v: Vertlet, deltaTime: CGFloat, deltaTimeSquared: CGFloat) -> CGPoint {
        return force
    }
}


class DamperForce: Force {
    let coefficient: CGFloat
    init(coefficient: CGFloat) {
        self.coefficient = coefficient
    }
    
    func apply(v: Vertlet, deltaTime: CGFloat, deltaTimeSquared: CGFloat) -> CGPoint {
        return -coefficient * v.velocity
    }
}


class SpringForce: Force {
    let coefficient: CGFloat
    let target: Vertlet
    let distance: CGFloat
    let targetOffset: CGPoint
    
    init(coefficient: CGFloat, target: Vertlet, distance: CGFloat, targetOffset: CGPoint = .zero) {
        self.coefficient = coefficient
        self.target = target
        self.distance = distance
        self.targetOffset = targetOffset
    }
    
    func apply(v: Vertlet, deltaTime: CGFloat, deltaTimeSquared: CGFloat) -> CGPoint {
        let delta = target.position + targetOffset - v.position
        return -coefficient * (distance - delta.magnitude()) * (delta.normal())
    }
}


class InteractionDraggingConstraint: Constraint {
    let position: PositionCell
    let dragPoint: PositionCell
    let falloff: CGFloat
    let targetOffset: CGPoint
    let onOff: OnOffCell
    let v: Vertlet
    
    init(v: Vertlet, position: PositionCell, dragPoint: PositionCell, targetOffset: CGPoint = .zero, falloff: CGFloat, onOff: OnOffCell) {
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

class Vertlet {
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


protocol Constraint {
    mutating func relaxConstraint()
}


class PositionCell: ObservableObject {
    var position: CGPoint = .zero
}

class OnOffCell: ObservableObject {
    var on: Bool = false
}

class DistanceCell: ObservableObject {
    var distance: CGFloat
    
    init(distance: CGFloat) {
        self.distance = distance
    }
    
}


class LockPositionConstraint : Constraint {
    var v: Vertlet
    var p : PositionCell
    var offset : CGPoint
    
    init(v: Vertlet, p: PositionCell, offset: CGPoint){
        self.v = v
        self.p = p
        self.offset = offset
    }
    
    convenience init(v: Vertlet, p: PositionCell) {
        self.init(v: v, p: p, offset: .zero)
    }
    
    func relaxConstraint() {
        v.position = p.position + offset
    }
}


class UnidirectionalDistanceToVertletConstraint : Constraint {
    var target: Vertlet
    var v: Vertlet
    var targetDistance: DistanceCell
    
    init(target: Vertlet, v: Vertlet, targetDistance: DistanceCell) {
        self.target = target
        self.v = v
        self.targetDistance = targetDistance
    }
    
    func relaxConstraint() {
        let direction = (target.position - v.position).normal()
        let deltaD = (target.position - v.position).magnitude() - CGFloat(targetDistance.distance)
        v.position = v.position + (deltaD * direction)
    }
}

class BidirectionalDistanceToVertletConstraint: Constraint {
    var v1: Vertlet
    var v2: Vertlet
    var targetDistance: DistanceCell
    
    init(v1: Vertlet, v2: Vertlet, targetDistance: DistanceCell) {
        self.v1 = v1
        self.v2 = v2
        self.targetDistance = targetDistance
    }
    
    func relaxConstraint() {
        let direction = (v2.position - v1.position).normal()
        let deltaD = (v1.position - v2.position).magnitude() - targetDistance.distance
        v1.position = v1.position + (deltaD*direction) * CGFloat(0.5)
        v2.position = v2.position - (deltaD*direction) * CGFloat(0.5)
    }
}



class RopeVertletSimulation: ObservableObject {
    var vertlets: [Vertlet] = []
    var constraints: [Constraint] = []
    private var targetDistanceCell : DistanceCell = DistanceCell(distance: 50)
    private var gravity: CGPoint = CGPoint(x: 0, y: 200)
    
    var targetDistance: CGFloat {
        get {
            return targetDistanceCell.distance
        }
        
        set {
            targetDistanceCell.distance = newValue
        }
    }
    
    
    private var startPositionCell : PositionCell = PositionCell()
    
    var startPosition: CGPoint {
        get {
            return startPositionCell.position
        }
        
        set {
            startPositionCell.position = newValue
        }
    }
    
    private var endPositionCell : PositionCell = PositionCell()
    var endPosition: CGPoint {
        get {
            return endPositionCell.position
        }
        
        set {
            endPositionCell.position = newValue
        }
    }
    
    
    var iterations: Int = 20
    var simulationTask: Task<Void, Error>? = nil
    
    func setup(start: CGPoint, end: CGPoint, particleCount: Int, iterations: Int) {
        constraints = []
        vertlets = []
        self.iterations = iterations
        self.targetDistance = 50
        let gravitationalForce = ConstantForce(force: gravity)
        
        let startVertlet = Vertlet(acceleration: CGPoint(x: 0, y: 200), position: start, velocity: .zero)
        vertlets.append(startVertlet)
        self.constraints.append(LockPositionConstraint(v: startVertlet, p: startPositionCell))
        
        let endVertlet = Vertlet(acceleration: CGPoint(x: 0, y: 200), position: end, velocity: .zero)
        self.constraints.append(LockPositionConstraint(v: endVertlet, p: endPositionCell))
        vertlets.append(endVertlet)
        

        for i in 1..<(particleCount-1) {
            let position = CGPoint.lerp(a: start, b: end, t: Float(i)  / Float(particleCount))
            let previousVertlet = vertlets.last!;
            let currentVertlet = Vertlet(acceleration: CGPoint(x: 0, y: 200), position: position, velocity: .zero)
            currentVertlet.forces.append(gravitationalForce)
            vertlets.append(currentVertlet)
            
            if (i == 1) {
                constraints.append(UnidirectionalDistanceToVertletConstraint(target: previousVertlet, v: currentVertlet, targetDistance: targetDistanceCell))
            } else if(i < particleCount-2) {
                constraints.append(BidirectionalDistanceToVertletConstraint(v1: previousVertlet, v2: currentVertlet, targetDistance: targetDistanceCell))
            } else {
                constraints.append(BidirectionalDistanceToVertletConstraint(v1: previousVertlet, v2: currentVertlet, targetDistance: targetDistanceCell))
                constraints.append(UnidirectionalDistanceToVertletConstraint(target: endVertlet, v: currentVertlet, targetDistance: targetDistanceCell))
            }
        }
        
    }
    
    @Sendable private func loop() async throws {
        let clock = SuspendingClock()
        var previousTime = clock.now
        while(true){
            let currentTime = clock.now
            let deltaTime = currentTime - previousTime
            previousTime = currentTime
            
            targetDistance = CGFloat(min(50, Float(max(0.01, (startPosition - endPosition).magnitude())) * Float(1.02 / max(Float(self.vertlets.count), 2))))
            
            let dt = Float(Double(deltaTime.components.attoseconds) * 1.0e-18)
            let dt2 = CGFloat(dt * dt)
            for v in self.vertlets {
                v.update(deltaTime: CGFloat(dt), deltaTimeSquared: dt2)
            }
                        
            for _ in 0..<iterations {
                for i in 0..<self.constraints.count {
                    self.constraints[i].relaxConstraint()
                }
            }
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
            await Task.yield()
        }
    }
    
    func startUpdate(){
        self.simulationTask = Task.detached(priority: .background, operation: self.loop)
    }
    
    
    func stopUpdate() {
        if let task = self.simulationTask {
            task.cancel()
        }
    }
   
}


class JellyBoxVertletSimulation: ObservableObject {
    var vertlets: [Vertlet] = []
    var anchorVertlet : Vertlet? = nil
    var renderVertlets: [Vertlet] = []
    var constraints: [Constraint] = []
    var dragConstraint: InteractionDraggingConstraint? = nil
    var dimensions : CGPoint = .zero
    private var gravity: CGPoint = CGPoint(x: 0, y: 0)
    
    var draggingCell: OnOffCell = OnOffCell()
    var dragging : Bool {
        get { draggingCell.on }
        set { draggingCell.on = newValue }
    }

    var updateIterations: Int = 5
    var constraintIterations: Int = 20
    var simulationTask: Task<Void, Error>? = nil
    
    var topLeftCell: PositionCell = PositionCell()
    var topLeft: CGPoint {
        get { topLeftCell.position}
        set {
            topLeftCell.position = newValue
        }
    }
    
    
    var dragPositionCell: PositionCell = PositionCell()
    var dragPosition: CGPoint {
        get { dragPositionCell.position}
        set { dragPositionCell.position = newValue }
    }
    
    
    
    func setup(dimensions: CGPoint, topLeft: CGPoint, particleDensity: Float, constraintIterations: Int, updateIterations: Int) {
        constraints = []
        vertlets = []
        self.dimensions = dimensions
        self.topLeft = topLeft
        self.dragPosition = topLeft
        renderVertlets = []
        self.updateIterations = updateIterations
        self.constraintIterations = constraintIterations
        
        let xCount = max(Int(ceilf(Float(dimensions.x) / particleDensity)), 2)
        let yCount = max(2, Int(ceilf(Float(dimensions.y) / particleDensity)))
        
        
        let xStride = CGPoint(x: dimensions.x / CGFloat(xCount), y: 0)
        let yStride = CGPoint(x: 0, y: dimensions.y / CGFloat(yCount))
                
        let gravitationalForce = ConstantForce(force: gravity)
        let dampingForce = DamperForce(coefficient: 4)

        
        var top: [Vertlet] = []
        var bottom: [Vertlet] = []
        var left: [Vertlet] = []
        var right: [Vertlet] = []
        
        let anchorVertlet = Vertlet(acceleration: .zero, position: topLeft, velocity: .zero)
        vertlets.append(anchorVertlet)
        constraints.append(LockPositionConstraint(v: anchorVertlet, p: topLeftCell))
        self.anchorVertlet = anchorVertlet
        
        for j in 0...yCount {
            for i in 0...xCount {
                let offset = xStride * CGFloat(i) + yStride * CGFloat(j)
                let initialPosition = topLeft + offset
                let vertlet = Vertlet(acceleration: .zero, position: initialPosition, velocity: .zero)
                if j == 0 {
                    top.append(vertlet)
                }
                else if j == yCount {
                    bottom.append(vertlet)
                } else if i == 0 {
                    left.append(vertlet)
                } else if i == xCount {
                    right.append(vertlet)
                }
                vertlet.forces.append(gravitationalForce)
                vertlet.forces.append(dampingForce)
                constraints.append(InteractionDraggingConstraint(v: vertlet, position: topLeftCell, dragPoint: dragPositionCell, targetOffset: offset, falloff: 100, onOff: draggingCell))
                vertlet.forces.append(SpringForce(coefficient: 50, target: anchorVertlet, distance: 0, targetOffset: offset))
                vertlets.append(vertlet)
            }
        }
        renderVertlets.append(contentsOf: top)
        renderVertlets.append(contentsOf: right)
        renderVertlets.append(contentsOf: bottom.reversed())
        renderVertlets.append(contentsOf: left.reversed())
    }
    
    @Sendable private func loop() async throws {
        let clock = SuspendingClock()
        var previousTime = clock.now
        while(true){
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
            await Task.yield()
        }
    }
    
    func startUpdate(){
        self.simulationTask = Task.detached(priority: .background, operation: self.loop)
    }
    
    
    func stopUpdate() {
        if let task = self.simulationTask {
            task.cancel()
        }
    }
   
}
