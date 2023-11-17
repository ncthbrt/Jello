//
//  Rioe.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/17.
//

import Foundation
import SwiftUI

fileprivate protocol Force {
    func apply(v: PositionVertlet, deltaTime: CGFloat, deltaTimeSquared: CGFloat) -> CGPoint
}

fileprivate class ConstantForce: Force {
    let force: CGPoint
    init(force: CGPoint) {
        self.force = force
    }
    
    func apply(v: PositionVertlet, deltaTime: CGFloat, deltaTimeSquared: CGFloat) -> CGPoint {
        return force
    }
}


fileprivate class LockPositionConstraint : Constraint {
    var v: PositionVertlet
    var p : PositionCell
    var offset : CGPoint
    
    init(v: PositionVertlet, p: PositionCell, offset: CGPoint){
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
        let deltaD = (target.position - v.position).magnitude() - CGFloat(targetDistance.distance)
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
        v1.position = v1.position + (deltaD*direction) * CGFloat(0.5)
        v2.position = v2.position - (deltaD*direction) * CGFloat(0.5)
    }
}



fileprivate class PositionVertlet {
    var acceleration: CGPoint
    var previousPosition: CGPoint
    var position: CGPoint
    var forces: [Force] = []
    var newAcceleration: CGPoint
    
    init(acceleration: CGPoint, position: CGPoint){
        self.acceleration = acceleration
        self.position = position
        self.previousPosition = position
        self.newAcceleration = acceleration
    }
    
    func prepareForces(deltaTime: CGFloat, deltaTimeSquared: CGFloat) {
        newAcceleration = applyForces(deltaTime: deltaTime, deltaTimeSquared: deltaTimeSquared)
    }
   
    func update(deltaTime: CGFloat, deltaTimeSquared: CGFloat){
        let positionCopy: CGPoint = CGPoint(x: position.x, y: position.y)
        self.position = CGFloat(2.0)*position - previousPosition + deltaTimeSquared*acceleration
        self.previousPosition = positionCopy
    }
    
    func applyForces(deltaTime: CGFloat, deltaTimeSquared: CGFloat) -> CGPoint {
        return forces.reduce(CGPoint.zero, {result, force in result + force.apply(v: self, deltaTime: deltaTime, deltaTimeSquared: deltaTimeSquared) })
    }
}


class RopeVertletSimulation: ObservableObject {
    private var vertlets: [PositionVertlet] = []
    private var constraints: [Constraint] = []
    private var targetDistanceCell : DistanceCell = DistanceCell(distance: 20)
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
    
    
    var iterations: Int = 10
    var simulationTask: Task<Void, Error>? = nil
    
    func setup(start: CGPoint, end: CGPoint, particleCount: Int, iterations: Int) {
        constraints = []
        vertlets = []
        self.iterations = iterations
        self.targetDistance = 20
        let gravitationalForce = ConstantForce(force: gravity)
        
        let startVertlet = PositionVertlet(acceleration: CGPoint(x: 0, y: 200), position: start)
        vertlets.append(startVertlet)
        self.constraints.append(LockPositionConstraint(v: startVertlet, p: startPositionCell))
        
        let endVertlet = PositionVertlet(acceleration: CGPoint(x: 0, y: 200), position: end)
        self.constraints.append(LockPositionConstraint(v: endVertlet, p: endPositionCell))
        

        for i in 1..<(particleCount-1) {
            let position = CGPoint.lerp(a: start, b: end, t: Float(i)  / Float(particleCount))
            let previousVertlet = vertlets.last!;
            let currentVertlet = PositionVertlet(acceleration: CGPoint(x: 0, y: 200), position: position)
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
        
        vertlets.append(endVertlet)
        
    }
    
    @Sendable private func loop() async throws {
        let clock = SuspendingClock()
        var previousTime = clock.now
        
        while(true){
            let currentTime = clock.now
            let deltaTime = currentTime - previousTime
            previousTime = currentTime
            targetDistance = CGFloat(min(50, Float(max(0.01, (startPosition - endPosition).magnitude())) * Float(1.02 / max(Float(self.vertlets.count), 2))))

            let dtDouble: Double = Double(deltaTime.components.attoseconds) * 1.0e-18
            let dt = CGFloat(dtDouble)
            let dt2 = CGFloat(dtDouble * dtDouble)
            
            for v in self.vertlets {
                v.prepareForces(deltaTime: dt, deltaTimeSquared: dt2)
            }
            for v in self.vertlets {
                v.update(deltaTime: dt, deltaTimeSquared: dt2)
            }
            
            for _ in 0..<iterations {
                for i in 0..<self.constraints.count {
                    self.constraints[i].relaxConstraint()
                }
            }
            DispatchQueue.main.asyncAndWait {
                self.objectWillChange.send()
            }
            try Task.checkCancellation()
            try await Task.sleep(for: Duration.milliseconds(16))
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
    
    func draw(path: inout Path){
        path.move(to: startPosition)
        for v in vertlets.dropFirst(1) {
            path.addLine(to: v.position)
        }
    }
   
}
