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
            var cluster = try Cluster.Argument.cluster(withName: invalidName, from: clusterArgs, for: arguments)
            let fileManager = FileManager.default
            let isUnitTest = arguments.get(unit) ?? false
            let isQuiet = arguments.get(quiet) ?? false
            let machineConfig = try config(for: machineArgs, using: fileManager, for: arguments)
            let queue = CreateMachineOperation.defaultQueue
            let printQueue = printOperationQueue()
            
            let managerNames = cluster.initialNames(for: .swarmManager)
            let workerNames = cluster.initialNames(for: .swarmWorker)
            let cephNames = cluster.initialNames(for: .cephNode)
            
            let createManagerOps = createMachineOps(withNames: managerNames, andConfig: machineConfig, isUnitTest: isUnitTest)
            queue.addOperations(createManagerOps, waitUntilFinished: false)
            let printCreateManagerErrors = createPrintErrorOps(forProcesses: createManagerOps)
            printQueue.addOperations(printCreateManagerErrors, waitUntilFinished: false)
            let printCreateManagerOutput = createPrintOutputOps(forCreateMachineOps: createManagerOps, isQuiet: isQuiet)
            printQueue.addOperations(printCreateManagerOutput, waitUntilFinished: false)
            
            queue.waitUntilAllOperationsAreFinished()
            printQueue.waitUntilAllOperationsAreFinished()
            try createManagerOps.forEach({ (machineOp) in
                if machineOp.terminationStatus == 0 {
                    cluster.nodes[Cluster.Kinds.swarmManager]?.append(machineOp.machineName)
                    try cluster.save(using: fileManager)
                }
            })
            
            try throwOnAny(processOperations: createManagerOps)
            
            if !isQuiet {
                print(NSLocalizedString("Cluster created successfully!", comment: "Cluster creation success message"))
            }
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
