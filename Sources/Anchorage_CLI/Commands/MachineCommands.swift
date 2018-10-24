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


func throwOnAny(processOperations: [ProcessOperation], withoutTerminationStatus requiredTerminationStatus: Int32 = 0) throws {
    try processOperations.forEach({ (op) in
        if op.terminationStatus != requiredTerminationStatus {
            throw CLIError.createMachineFailed(status: op.terminationStatus)
        }
    })
}


func createMachineOps(withNames machineNames: [String], andConfig machineConfig: MachineConfig, isUnitTest: Bool) -> [CreateMachineOperation] {
    return machineNames.map({ (name) -> CreateMachineOperation in
        return CreateMachineOperation(withName: name, andConfig: machineConfig, isUnit: isUnitTest)
    })
}

func createPrintErrorOps(forProcesses processOps: [ProcessOperation]) -> [BlockOperation] {
    return processOps.map({ (processOp) in
        return processOp.printErrorOperation()
    })
}

func createPrintOutputOps(forCreateMachineOps machineOps: [CreateMachineOperation], isQuiet: Bool) -> [BlockOperation] {
    return machineOps.map({ (machineOp) -> BlockOperation in
        let name = machineOp.machineName
        let responseBlock = {
            if machineOp.terminationStatus == 0 {
                print(isQuiet ? name : "Created machine " + name)
            }
        }
        return isQuiet ? machineOp.afterOp(responseBlock) : machineOp.printOutputOperation(and: responseBlock)
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
            let queue = CreateMachineOperation.defaultQueue
            let printQueue = printOperationQueue()
            let machineOps = createMachineOps(withNames: machineNames, andConfig: machineConfig, isUnitTest: isUnitTest)
            queue.addOperations(machineOps, waitUntilFinished: false)
            let errorOps = createPrintErrorOps(forProcesses: machineOps)
            printQueue.addOperations(errorOps, waitUntilFinished: false)
            let printOps = createPrintOutputOps(forCreateMachineOps: machineOps, isQuiet: isQuiet)
            printQueue.addOperations(printOps, waitUntilFinished: false)
            
            queue.waitUntilAllOperationsAreFinished()
            printQueue.waitUntilAllOperationsAreFinished()
            
            try throwOnAny(processOperations: machineOps)
            
            if !isQuiet {
                print(NSLocalizedString("Machines created successfully!", comment: "Machine creation success message"))
            }
    })
}
