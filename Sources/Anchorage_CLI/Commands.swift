//
//  Commands.swift
//  Anchorage_CLI
//
//  Created by Robert Harrison on 15/10/2018.
//

import Foundation
import Utility
import Basic
import Anchorage

struct Command {
    let name: String
    let run: (ArgumentParser.Result) throws -> Void
}



func namesArgument(for commandParser: ArgumentParser) -> PositionalArgument<[String]> {
    return commandParser.add(
        positional: "names", kind: [String].self,
        optional: false, strategy: .upToNextOption,
        usage: NSLocalizedString("name [name] [name] ...", comment: "Name argument usage"),
        completion: .none
    )
}

func nameArgument(for commandParser: ArgumentParser) -> PositionalArgument<String> {
    return commandParser.add(positional: "name", kind: String.self, optional: false, usage: NSLocalizedString("The name of the cluster", comment: "Name argument usage"), completion: .none)
}

func unitTest(for commandParser: ArgumentParser) -> OptionArgument<Bool>{
    let usage = NSLocalizedString("If specified will print commands which will be run rather than actually performing those commands", comment: "Unit test usage")
    return commandParser.add(option: "--unit-test", shortName: nil, kind: Bool.self, usage: usage, completion: ShellCompletion.values([(value: "true", description: "The value for a boolean true"), (value: "false", description: "The value for a boolean false")]))
}

func quietArgument(for commandParser: ArgumentParser) -> OptionArgument<Bool> {
    let usage = NSLocalizedString("Limit output to IDs only.  Generally used for scripting", comment: "Quiet Usage")
    return commandParser.add(option: "--quiet", shortName: "-q", kind: Bool.self, usage: usage, completion: ShellCompletion.values([(value: "true", description: "The value for a boolean true"), (value: "false", description: "The value for a boolean false")]))
}


func rootCommands(for argumentParser: ArgumentParser) -> [Command] {
    return [
        clusterCommand(for: argumentParser),
        machineCommand(for: argumentParser)
    ]
}




func printOperationQueue() -> OperationQueue {
    let printQueue = OperationQueue()
    printQueue.maxConcurrentOperationCount = 1
    printQueue.name = "Output OperationQueue: printQueue"
    return printQueue
}




//
//enum CommandKind: String {
//    case cluster
//    case create
//    case rm
//    case ls
//
//    var overview: String {
//        switch self {
//        case .cluster:
//            return
//        case .create:
//            return
//        case .ls:
//            return
//        case .rm:
//            return
//        }
//    }
//
//    func add(to argumentParser: ArgumentParser) -> Command {
//        switch self {
//        case .cluster, .create, .rm, .ls:
//            let commandParser = argumentParser.add(subparser: String(describing: self), overview: self.overview)
//            let subCommands = self.subcommands.map { (command) -> Command in
//                return command.add(to: commandParser)
//            }
//            let positionalArguments = self.positionalArguments.map { (argument) -> Any in
//                return argument.add(to: commandParser)
//            }
//            return Command(kind: self, commandParser: commandParser, subCommands: subCommands, positionalArguments: positionalArguments)
//        }
//    }
//
//    var subcommands: [CommandKind] {
//        switch self {
//        case .cluster:
//            return [.create, .ls, .rm]
//        default:
//            return []
//        }
//    }
//
//    var positionalArguments: [ArgumentKind] {
//        switch self {
//        case .create, .rm:
//            return [.name]
//        default:
//            return []
//        }
//    }
//
//
//}
//
//enum ArgumentKind {
//    case name
//
//    var usage: String {
//        switch self {
//        case .name:
//            return "ArgumentUsage"
//        }
//    }
//
//    func add(to argumentParser: ArgumentParser) -> PositionalArgument<String> {
//        switch self {
//        case .name:
//            return argumentParser.add(positional: String(describing: self), kind: String.self, optional: false, usage: self.usage, completion: .none)
//        }
//    }
//}
//
//
//
//struct Command {
//    let kind: CommandKind
//    let commandParser: ArgumentParser
//    let subCommands: [Command]
//    let positionalArguments: [Any]
//}
