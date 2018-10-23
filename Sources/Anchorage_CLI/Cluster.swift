//
//  Cluster.swift
//  Anchorage_CLI
//
//  Created by Robert Harrison on 23/10/2018.
//

import Foundation

//
//  Machine.swift
//  Anchorage_CLI
//
//  Created by Robert Harrison on 22/10/2018.
//

import Foundation
import Utility
import Basic
import Anchorage

public extension Cluster.Argument  {
    
    var usage: String {
        switch self {
        case .swarmManagers:
            return NSLocalizedString("The number of swarm managers to create, a minimum of 1 is required for a docker swarm to be created, default 0.", comment: "Swarm manager number usage")
        case .swarmWorkers:
            return NSLocalizedString("The number of swarm workers to create, default 0.", comment: "Swarm worker number usage")
        case .ceph:
            return NSLocalizedString("The number of ceph storage nodes to create, default 0.", comment: "Swarm worker number usage")
        }
    }
    
    func argument(for commandParser: ArgumentParser) -> Any {
        switch self {
        case .swarmManagers, .swarmWorkers, .ceph:
            return commandParser.add(
                option: self.argumentName, shortName: self.argumentShortName,
                kind: Int.self,
                usage: self.usage,
                completion: ShellCompletion.none)
        }
    }
    
    static func arguments(for commandParser: ArgumentParser) -> [Cluster.Argument: Any] {
        return Cluster.Argument.allCases.reduce(into: [Cluster.Argument: Any](), { (result, arg) in
            result[arg] = arg.argument(for: commandParser)
        })
    }
    
    public static func value<T>(for arg: Cluster.Argument, from args: [Cluster.Argument: Any], for result: ArgumentParser.Result) -> T? {
        guard let parser = args[arg] else {
            return nil
        }
        return arg.value(for: parser, for: result)
    }

    func value<T>(for arg: Any, for result: ArgumentParser.Result) -> T {
        switch self {
        case .swarmManagers, .swarmWorkers, .ceph:
            guard let i = result.get(arg as! OptionArgument<T>) else {
                return 0 as! T
            }
            return i
        }
    }
}

//func defaultConfig(forCluster cluster: String, using fileManager: FileManager) throws -> MachineConfig {
//    if let config = try Cluster.defaultMachineConfig(with: cluster, using: fileManager) {
//        return config
//    }
//    return try defaultConfig(with: fileManager)
//}
//
//func config(for machineArguments: [MachineArgument: Any], andCluster cluster: String, using fileManager: FileManager, for result: ArgumentParser.Result) throws -> MachineConfig {
//    return try MachineArgument.set(machineArguments: machineArguments, on: defaultConfig(forCluster: cluster, using: fileManager), for: result)
//}
//
//func config(for machineArguments: [MachineArgument: Any], using fileManager: FileManager, for result: ArgumentParser.Result) throws -> MachineConfig {
//    return try MachineArgument.set(machineArguments: machineArguments, on: try defaultConfig(with: fileManager), for: result)
//}
