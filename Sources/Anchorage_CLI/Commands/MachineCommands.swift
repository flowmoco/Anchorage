//
//  MachineCommands.swift
//  Anchorage_CLI
//
//  Created by Robert Harrison on 23/10/2018.
//

import Foundation
import Utility
import Anchorage

func machineCommand(for argumentParser: ArgumentParser) -> Command {
    let name = "machine"
    let commandParser = argumentParser.add(
        subparser: name,
        overview: NSLocalizedString("Create, destroy and manage machines outside of cluster.",
                                    comment: "Machine command overview")
    )
    let subcommands = machineSubcommands(for: commandParser)
    return Command(
        name: name,
        run: { (arguments) in
            try run(commands: subcommands, for: commandParser, giving: arguments)
    })
}

func machineSubcommands(for argumentParser: ArgumentParser) -> [Command] {
    return [
        machineCreateCommand(for: argumentParser)
    ]
}

func validMachine(names: [String]?, commandParser: ArgumentParser) throws -> [String] {
    guard let machineNames = names, !machineNames.isEmpty else {
        throw ArgumentParserError.expectedArguments(commandParser, ["names"])
    }
    return try machineNames.map({ (name) -> String in
        return try valid(identifier: name)
    })
}

func machineCreateCommand(for argumentParser: ArgumentParser) -> Command {
    let name = "create"
    let commandParser = argumentParser.add(
        subparser: name,
        overview: NSLocalizedString("Create a machine.",
                                    comment: "Machine command overview")
    )
    //    let (awsAccessKey, awsSecretKey) = awsAccessArguments(for: commandParser)
    let machineNameArgs = namesArgument(for: commandParser)
    let unit = unitTest(for: commandParser)
    let machineArgs = MachineArgument.arguments(for: commandParser)
    let quiet = quietArgument(for: commandParser)
    return Command(
        name: name,
        run: { (arguments) in
            let fileManager = FileManager.default
            let isUnitTest = arguments.get(unit) ?? false
            let isQuiet = arguments.get(quiet) ?? false
            let machineConfig = try config(for: machineArgs, using: fileManager, for: arguments)
            let machineNames = try validMachine(names: arguments.get(machineNameArgs), commandParser: commandParser)
            var exitStatus: Int32?
            let queue = CreateMachineOperation.defaultQueue
            let printQueue = printOperationQueue()
            machineNames.forEach({ (name) in
                let op = CreateMachineOperation(withName: name, andConfig: machineConfig, isUnit: isUnitTest)
                let completionOp = BlockOperation {
                    
                    if !isQuiet, let output = op.standardOutput, !output.isEmpty {
                        print(output)
                    }
                    if let error = op.standardError, !error.isEmpty {
                        print(errorMessage: error)
                    }
                    if op.terminationStatus == 0 {
                        print(isQuiet ? name : "Created machine " + name)
                    } else {
                        exitStatus = op.terminationStatus
                    }
                }
                completionOp.addDependency(op)
                queue.addOperation(op)
                printQueue.addOperation(completionOp)
            })
            queue.waitUntilAllOperationsAreFinished()
            printQueue.waitUntilAllOperationsAreFinished()
            if let exitStatus = exitStatus {
                throw CLIError.createMachineFailed(status: exitStatus)
            }
            if !isQuiet {
                print(NSLocalizedString("Machines created successfully!", comment: "Machine creation success message"))
            }
    })
}
