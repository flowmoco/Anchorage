//
//  ClusterCommands.swift
//  Anchorage_CLI
//
//  Created by Robert Harrison on 23/10/2018.
//

import Foundation
import Utility
import Anchorage

func clusterCommand(for argumentParser: ArgumentParser) -> Command {
    let name = "cluster"
    let commandParser = argumentParser.add(
        subparser: name,
        overview: NSLocalizedString("Create, destroy and manage clusters.",
                                    comment: "Cluster command overview")
    )
    let subcommands = clusterSubcommands(for: commandParser)
    return Command(
        name: name,
        run: { (arguments) in
            try run(commands: subcommands, for: commandParser, giving: arguments)
    })
}

func createClusterCommand(for argumentParser: ArgumentParser) -> Command {
    let name = "create"
    let commandParser = argumentParser.add(
        subparser: name,
        overview: NSLocalizedString("Create new clusters.", comment: "Create command overview")
    )
    let unit = unitTest(for: commandParser)
    let quiet = quietArgument(for: commandParser)
    let clusterArgs = Cluster.Argument.arguments(for: commandParser)
    let machineArgs = MachineArgument.arguments(for: commandParser)
    let clusterName = nameArgument(for: commandParser)
    
    return Command(
        name: name,
        run: { (arguments) in
            guard let invalidName = arguments.get(clusterName) else {
                throw ArgumentParserError.expectedArguments(commandParser, ["names"])
            }
            let cluster = try Cluster.Argument.cluster(withName: invalidName, from: clusterArgs, for: arguments)
            let fileManager = FileManager.default
            let isUnitTest = arguments.get(unit) ?? false
            let isQuiet = arguments.get(quiet) ?? false
            let machineConfig = try config(for: machineArgs, using: fileManager, for: arguments)
            let queue = CreateMachineOperation.defaultQueue
            let mainQueue = OperationQueue.main

            let managerNames = cluster.initialNames(for: .swarmManager)
            let workerNames = cluster.initialNames(for: .swarmWorker)
            let cephNames = cluster.initialNames(for: .cephNode)
            
            let (createManagerOps, createManagerPrintOps) = createMachineOps(withNames: managerNames, andConfig: machineConfig, isUnitTest: isUnitTest, isQuiet: isQuiet)
            queue.addOperations(createManagerOps, waitUntilFinished: false)
            mainQueue.addOperations(createManagerPrintOps, waitUntilFinished: false)
            
            // Create Manager Swarm
            let createSwarmOp: InitializeSwarm?
            if createManagerOps.count >= 1 {
                let envVars = MachineEnvironmentOperation(withName: createManagerOps[0].machineName, isUnit: isUnitTest)
                envVars.addDependency(createManagerOps[0])
                queue.addOperation(envVars)
                
                let createSwarm = InitializeSwarm(envVarsOp: envVars, advertiseAddress: nil, createMachineOp: createManagerOps[0], isUnit: isUnitTest)
                queue.addOperation(createSwarm)
                createSwarmOp = createSwarm
                
                
            } else {
                createSwarmOp = nil
            }

            let (createWorkerOps, createWorkerPrintOps) = createMachineOps(withNames: workerNames, andConfig: machineConfig, isUnitTest: isUnitTest, isQuiet: isQuiet)
            queue.addOperations(createWorkerOps, waitUntilFinished: false)
            mainQueue.addOperations(createWorkerPrintOps, waitUntilFinished: false)
            
            let (createCephNodeOps, createCephNodePrintOps) = createMachineOps(withNames: cephNames, andConfig: machineConfig, isUnitTest: isUnitTest, isQuiet: isQuiet)
            queue.addOperations(createCephNodeOps, waitUntilFinished: false)
            mainQueue.addOperations(createCephNodePrintOps, waitUntilFinished: false)
            
            let saveClusterMachines = BlockOperation {
                do {
                    try Cluster.Kinds.allCases.reduce(cluster, { (cluster, kind) -> Cluster in
                        let ops: [CreateMachineOperation]
                        switch kind {
                        case .swarmManager:
                            ops = createManagerOps
                        case .swarmWorker:
                            ops = createWorkerOps
                        case .cephNode:
                            ops = createCephNodeOps
                        }
                        return cluster.addingMachinesToCluster(createMachineOps: ops,
                                                               kind: kind
                        ).addingDefault(machineConfig: machineConfig,
                                        forKind: kind
                        )
                    }).save(using: fileManager)
                } catch {
                    print(errorMessage: NSLocalizedString("Error saving cluster.  Please ensure you have write access to the ~/.anchorage/clusters directory.", comment: "Error saving cluster file"))
                    exit(1)
                }
            }
            
            Cluster.Kinds.allCases.reduce([Operation](), { (out, kind) -> [Operation] in
                switch kind {
                case .swarmManager:
                    return out + createManagerOps
                case .swarmWorker:
                    return out + createWorkerOps
                case .cephNode:
                    return out + createCephNodeOps
                }
            }).forEach({ (op) in
                saveClusterMachines.addDependency(op)
            })

            mainQueue.addOperation(saveClusterMachines)
            
            let exitOp = reportErrorsFrom(processOperations: createManagerOps + createWorkerOps + [ createSwarmOp ], successMessage: NSLocalizedString("Cluster created successfully!", comment: "Cluster creation success message"))
            exitOp.addDependency(saveClusterMachines)
            
            Cluster.Kinds.allCases.reduce([Operation](), { (out, kind) -> [Operation] in
                switch kind {
                case .swarmManager:
                    return out + createManagerPrintOps
                case .swarmWorker:
                    return out + createWorkerPrintOps
                case .cephNode:
                    return out + createCephNodePrintOps
                }
            }).forEach({ (op) in
                exitOp.addDependency(op)
            })
            
            mainQueue.addOperation(exitOp)
            dispatchMain()
            
    })
}

func removeClusterCommand(for argumentParser: ArgumentParser) -> Command {
    let name = "rm"
    let commandParser = argumentParser.add(
        subparser: name,
        overview: NSLocalizedString("Delete the specified cluster", comment: "rm command overview")
    )
//    let clusterNames = namesArgument(for: commandParser)
    return Command(
        name: name,
        run: { (arguments) in
            let _ = commandParser
            // code
    })
}


func listClustersCommand(for argumentParser: ArgumentParser) -> Command {
    let name = "ls"
    let commandParser = argumentParser.add(
        subparser: name,
        overview: NSLocalizedString("List all managed clusters.", comment: "List command overview")
    )
    return Command(
        name: name,
        run: { (arguments) in
            // code
            let _ = commandParser
    })
}

func clusterSubcommands(for commandParser: ArgumentParser) -> [Command] {
    return [
        removeClusterCommand(for: commandParser),
        createClusterCommand(for: commandParser),
        listClustersCommand(for: commandParser)
    ]
}
