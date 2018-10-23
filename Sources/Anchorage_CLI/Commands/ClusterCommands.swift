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
    let _ = clusterSubcommands(for: commandParser)
    return Command(
        name: name,
        run: { (arguments) in
            // code
    })
}

func createClusterCommand(for argumentParser: ArgumentParser) -> Command {
    let name = "create"
    let commandParser = argumentParser.add(
        subparser: name,
        overview: NSLocalizedString("Create new clusters.", comment: "Create command overview")
    )
    let unit = unitTest(for: commandParser)
    let clusterArgs = Cluster.Argument.arguments(for: commandParser)
    let machineArgs = MachineArgument.arguments(for: commandParser)
    let clusterNames = nameArgument(for: commandParser)
    return Command(
        name: name,
        run: { (arguments) in
            let isUnitTest = arguments.get(unit) ?? false
            let swarmManagers: Int = Cluster.Argument.value(for: .swarmManagers, from: clusterArgs, for: arguments)!
            let swarmWorkers: Int = Cluster.Argument.value(for: .swarmWorkers, from: clusterArgs, for: arguments)!
            let ceph: Int = Cluster.Argument.value(for: .ceph, from: clusterArgs, for: arguments)!
            // code
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
