//
//  InitializeSwarm.swift
//  Anchorage
//
//  Created by Robert Harrison on 31/10/2018.
//

import Foundation

public class InitializeSwarm: ProcessOperation {
    
    let environmentVariablesOp: MachineEnvironmentOperation
    let createMachineOp: CreateMachineOperation?
    let advertiseAddress: String?
    
    public init(envVarsOp: MachineEnvironmentOperation, advertiseAddress: String? = nil, createMachineOp: CreateMachineOperation? = nil, isUnit: Bool) {
        environmentVariablesOp = envVarsOp
        self.createMachineOp = createMachineOp
        self.advertiseAddress = advertiseAddress
        super.init(
            commands: [
                "docker", "swarm", "init"
            ], isUnit: isUnit)
        self.addDependency(envVarsOp)
        if let createMachineOp = createMachineOp {
            self.addDependency(createMachineOp)
        }
    }
    
    public override func main() {
        
        guard let environment = environmentVariablesOp.environmentVariables else {
            self.state = .finished
            return
        }
        
        if let advertiseAddress = self.advertiseAddress {
            process.arguments?.append(contentsOf: ["--advertise-addr", advertiseAddress])
        } else if let createMachineOp = self.createMachineOp {
            if createMachineOp.terminationStatus != 0 || createMachineOp.error != nil {
                self.state = .finished
                return
            }
            if let ip = Machine.named(createMachineOp.machineName, using: FileManager())?.Driver.PrivateIPAddress, ip.isEmpty == false {
                process.arguments?.append(contentsOf: ["--advertise-addr", ip])
            } else {
                print(errorMessage: NSLocalizedString("Warning: Could not get Private IP of machine to create swarm", comment: "Error creating swarm"))
            }
        }
        
        self.process.environment = environment
        super.main()
    }
    
}
