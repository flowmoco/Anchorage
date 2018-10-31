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


func reportErrorsFrom(processOperations: [ProcessOperation?], successMessage: String, withoutTerminationStatus requiredTerminationStatus: Int32 = 0) -> BlockOperation {
    
    let out = BlockOperation {
        var didError = false
        processOperations.forEach({ (op) in
            guard let op = op else {
                return
            }
            if op.terminationStatus != requiredTerminationStatus {
                let name = op.name ?? "Unknown Process"
                print(errorMessage: "\(name) failed with termination status code \(op.terminationStatus)")
                didError = true
            }
        })
        if didError {
            print(errorMessage: "Exiting due to unexpected subprocess non \(requiredTerminationStatus) termination status code.")
            exit(1)
        } else {
            print(successMessage)
            exit(0)
        }
    }
    processOperations.forEach { (op) in
        guard let op = op else {
            return
        }
        out.addDependency(op)
    }
    
    return out
}


func createMachineOps(withNames machineNames: [String], andConfig machineConfig: MachineConfig, isUnitTest: Bool, isQuiet: Bool) -> ([CreateMachineOperation], [BlockOperation]) {
    var printOps = [BlockOperation]()
    let machineOps = machineNames.map({ (name) -> CreateMachineOperation in
        let machineOp = CreateMachineOperation(withName: name, andConfig: machineConfig, isUnit: isUnitTest)
        printOps.append(machineOp.printErrorOperation())
        let responseBlock = {
            if machineOp.terminationStatus == 0 {
                print(isQuiet ? name : "Created machine " + name)
            }
        }
        if isQuiet {
            printOps.append(machineOp.afterOp(responseBlock))
        } else {
            printOps.append(machineOp.printOutputOperation(and: responseBlock))
        }
        return machineOp
    })
    return (machineOps, printOps)
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
            let mainQueue = OperationQueue.main
            
            let (machineOps, printOps) = createMachineOps(withNames: machineNames, andConfig: machineConfig, isUnitTest: isUnitTest, isQuiet: isQuiet)
            queue.addOperations(machineOps, waitUntilFinished: false)
            mainQueue.addOperations(printOps, waitUntilFinished: false)
            
            let exitOp = reportErrorsFrom(processOperations: machineOps, successMessage: NSLocalizedString("Machines created successfully!", comment: "Machine creation success message"))
            printOps.forEach({ (op) in
                exitOp.addDependency(op)
            })
            mainQueue.addOperation(exitOp)
            dispatchMain()
    })
}
