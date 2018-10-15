//
//  Commands.swift
//  Anchorage_CLI
//
//  Created by Robert Harrison on 15/10/2018.
//

import Foundation
import Utility
import Basic

struct Command {
    let name: String
    let run: (ArgumentParser.Result) throws -> Void
}

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
            // code
    })
}

func namesArgument(for commandParser: ArgumentParser) -> PositionalArgument<[String]> {
    return commandParser.add(
        positional: "names", kind: [String].self,
        optional: false, strategy: .upToNextOption,
        usage: NSLocalizedString("name [name] [name] ...", comment: "Name argument usage"),
        completion: .none
    )
}

func createClusterCommand(for argumentParser: ArgumentParser) -> Command {
    let name = "create"
    let commandParser = argumentParser.add(
        subparser: name,
        overview: NSLocalizedString("Create new clusters.", comment: "Create command overview")
    )
    let clusterNames = namesArgument(for: commandParser)
    return Command(
        name: name,
        run: { (arguments) in
            // code
    })
}

func removeClusterCommand(for argumentParser: ArgumentParser) -> Command {
    let name = "rm"
    let commandParser = argumentParser.add(
        subparser: name,
        overview: NSLocalizedString("Delete the specified cluster", comment: "rm command overview")
    )
    let clusterNames = namesArgument(for: commandParser)
    return Command(
        name: name,
        run: { (arguments) in
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
    })
}

func clusterSubcommands(for commandParser: ArgumentParser) -> [Command] {
    return [
        removeClusterCommand(for: commandParser),
        createClusterCommand(for: commandParser),
        listClustersCommand(for: commandParser)
    ]
}

func rootCommands(for argumentParser: ArgumentParser) -> [Command] {
    return [
        clusterCommand(for: argumentParser)
    ]
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
