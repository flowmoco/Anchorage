//
//  MachineEnvironmentOperation.swift
//  Anchorage
//
//  Created by Robert Harrison on 31/10/2018.
//

import Foundation

public class MachineEnvironmentOperation: ProcessOperation {
    
    public let machineName: String
    public var environmentVariables: [String: String]?
    
    public init(withName name: String, isUnit: Bool) {
        self.machineName = name
        super.init(
            commands: [
                "docker-machine", "env"
                ] + [ name ], isUnit: isUnit)
    }
    
    public override func processTerminated() {
        if self.terminationStatus == 0 {
            if let out = self.standardOutput {
                self.environmentVariables = Anchorage.environmentVariables(forDockerMachineOutput: out)
            }
        } else if let err = standardError {
            print(errorMessage: err)
        }
        super.processTerminated()
    }
    
}
