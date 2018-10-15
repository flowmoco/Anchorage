//
//  File.swift
//  Anchorage
//
//  Created by Robert Harrison on 10/10/2018.
//

import Foundation

enum MachineErrors: Error, LocalizedError {
    case invalid(name: String)
    case processMissingPipeFor(commandName: String?)
    case unableToLaunchProcessFor(commands: [String], message: String)
    case processExitedWithStatus(status: Int32, processID: Int32,
        reason: Process.TerminationReason, output: String
    )
    
    var localizedDescription: String {
        switch self {
        case .invalid(let name):
            return String(format: NSLocalizedString("'%@' is not a valid machine name, which should only contain the following characers: [a-zA-Z0-9\\-]", comment: "Invalid name"), name)
        case .processMissingPipeFor(let commandName):
            if let commandName = commandName {
                return String(format: NSLocalizedString("%@ command process was missing a pipe to collect output", comment: "An error message for pipe"), commandName)
            } else {
                return NSLocalizedString("Command process was missing a pipe for an unknown command", comment: "An error message for pipe")
            }
        case .unableToLaunchProcessFor(let commands, let message):
            if commands.count > 0 {
                let format = NSLocalizedString("Unable to launch the following process, please check the following command is valid on your system and that you have the required dependancies installed: '%@'\n%@", comment: "Error making process")
                return String(format: format, commands.joined(separator: " "), message)
            } else {
                return String(format: NSLocalizedString("A command was launched with no arguments, please ensure you have all the required dependancies installed.  If so, please report this bug.\n%@", comment: "Command with no arguments launched."), message)
            }
        case .processExitedWithStatus(let status, let processID, let reason, let output):
            let reasonString: String
            switch reason {
            case .exit:
                reasonString = NSLocalizedString("The process exited.", comment: "Process exit reason")
            case .uncaughtSignal:
                reasonString = NSLocalizedString("The process exited due to an uncaught signal.", comment: "Process exit reason")
            }
            let format = NSLocalizedString("Process ID '%@' exited with status '%@'\n%@\n%@\n\n%@", comment: "Process exit with error formatter")
            return String(format: format, String(processID), String(status), reasonString, output)
        }
    }
}

extension MachineErrors: CustomStringConvertible {
    var description: String {
        return "MachineError: " + self.localizedDescription
    }
}

public typealias StorageDriver = String

public struct MachineConfig: Encodable, Decodable {
    public var configVersion: Int
    public var driver: Driver
    public var engineStorageDriver: StorageDriver?
}

func valid(identifier: String) throws -> String {
    if let _ = identifier.range(of: "^[a-zA-Z\\-0-9]{3,128}$", options: .regularExpression, range: nil, locale: nil) {
        return identifier
    } else {
        throw MachineErrors.invalid(name: identifier)
    }
}

public func createMachine(withName name: String, andConfig config: MachineConfig) throws {
    let name = try valid(identifier: name)
    
}

func process(commands: [String],
             currentDirectory: URL,
             environment: [String: String]? = nil,
             qualityOfService: QualityOfService = QualityOfService.utility) throws -> Process {
    let process = Process()
    process.arguments = commands
    process.environment = environment ?? ProcessInfo.processInfo.environment
    process.standardError = Pipe()
    process.standardOutput = Pipe()
    process.qualityOfService = qualityOfService
    if #available(OSX 10.13, *) {
        process.currentDirectoryURL = currentDirectory
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    } else {
        process.currentDirectoryPath = currentDirectory.path
        process.launchPath = "/usr/bin/env"
    }
    do {
        if #available(OSX 10.13, *) {
            try process.run()
        } else {
            process.launch()
        }
    } catch {
        throw MachineErrors.unableToLaunchProcessFor(commands: commands, message: error.localizedDescription)
    }
    return process
}

func wait(forProcess process: Process) throws -> String {
    guard let errorPipe = process.standardError as? Pipe, let outputPipe = process.standardOutput as? Pipe else {
        throw MachineErrors.processMissingPipeFor(commandName: process.arguments?.first)
    }
    process.waitUntilExit()
    let status = process.terminationStatus
    if status == 0 {
        return String(bytes: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    } else {
        throw MachineErrors.processExitedWithStatus(status: status, processID: process.processIdentifier, reason: process.terminationReason, output: String(bytes: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "")
    }
}
