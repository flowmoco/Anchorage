//
//  GetSwarmJoinToken.swift
//  Anchorage
//
//  Created by Robert Harrison on 01/11/2018.
//

import Foundation

public class GetSwarmJoinToken: ProcessOperation {
    
    let environmentVariablesOp: MachineEnvironmentOperation
    var managerJoinToken: String?
    var workerJoinToken: String?
    
    public init(envVarsOp: MachineEnvironmentOperation, isUnit: Bool) {
        environmentVariablesOp = envVarsOp
        super.init(
            commands: ["docker", "swarm", "join-token", "-q", "manager", "&&", "docker", "swarm", "join-token", "-q", "worker"],
            isUnit: isUnit
        )
        self.addDependency(envVarsOp)
    }
    
    public override func main() {
        guard let environment = environmentVariablesOp.environmentVariables else {
            self.state = .finished
            return
        }
        
        self.process.environment = environment
        super.main()
    }
    
    public override func processTerminated() {
        if self.terminationStatus == 0 {
            if let out = self.standardOutput {
                out.split(separator: "\n").enumerated().forEach { (index, token) in
                    let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
                    if index == 0 {
                        managerJoinToken = trimmed
                    } else if index == 1 {
                        workerJoinToken = trimmed
                    } else {
                        let message = NSLocalizedString("Warning: Unexpected additional output in swarm join token response: ", comment: "Warning message on join token")
                        print(errorMessage: message + trimmed)
                    }
                }
            }
        }
        if let err = standardError {
            print(errorMessage: err)
        }
        super.processTerminated()
    }
    
}
