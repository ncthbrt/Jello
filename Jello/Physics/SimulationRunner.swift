//
//  SimulationRunner.swift
//  Jello
//
//  Created by Natalie Cuthbert on 2023/11/22.
//

import Foundation
import SwiftUI

protocol SimulationDrawable {
    typealias DrawOperation = ((inout Path) -> Void)
    func update(dt: Float, dt2: Float) -> DrawOperation
    func sync(operation: @escaping DrawOperation)
}

actor SimulationActor {
    var simulations: Dictionary<UUID, any SimulationDrawable> = [:]
    
    func addSimulation(id: UUID, sim: any SimulationDrawable) {
        simulations[id] = sim
    }
    
    func removeSimulation(id: UUID) {
        simulations.removeValue(forKey: id)
    }
    
    func update(deltaTime: Duration) {
        let dtDouble: Double = Double(deltaTime.components.attoseconds) * 1.0e-18
        let dt = Float(dtDouble)
        let dt2 = Float(dtDouble * dtDouble)
        var funcs: [UUID: SimulationDrawable.DrawOperation] = [:]
        
        for sim in simulations {
            funcs[sim.key] = sim.value.update(dt: dt, dt2: dt2)
        }
        
        let sims = simulations
        let fs = funcs
        DispatchQueue.main.async {
            for sim in sims {
                sim.value.sync(operation: fs[sim.key]!)
            }
        }
    }

}

class SimulationRunner: ObservableObject {
    private var simulationTask: Task<Void, Error>? = nil
    private var simulationActor: SimulationActor = SimulationActor()

  
    @Sendable private func loop() async throws {
        let clock = SuspendingClock()
        var previousTime = clock.now

        while(true){
            let currentTime = clock.now
            let deltaTime = currentTime - previousTime
            previousTime = currentTime

            await simulationActor.update(deltaTime: deltaTime)
            try Task.checkCancellation()
            await Task.yield()
        }
    }
    
    
    func addSimulation(id: UUID, sim: any SimulationDrawable) async {
        await simulationActor.addSimulation(id: id, sim: sim)
    }
    
    func removeSimulation(id: UUID) {
        Task.detached(operation: {
            await self.simulationActor.removeSimulation(id: id)
        })
    }
    
    func start(){
        simulationTask = Task.detached(priority: .background) {
            try? await self.loop()
        }
    }
    
    func stop() {
        simulationTask?.cancel()
    }
}
