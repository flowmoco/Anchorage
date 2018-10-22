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

func remainingArguments(for commandParser: ArgumentParser) -> PositionalArgument<[String]> {
    return commandParser.add(
        positional: "docker-machine_arguments", kind: [String].self,
        optional: false, strategy: .remaining,
        usage: NSLocalizedString("Any arguments used by docker-machine", comment: "Name argument usage"),
        completion: .none
    )
}

func awsAccessArguments(for commandParser: ArgumentParser) -> (OptionArgument<String>, OptionArgument<String>){
    let akUsage = NSLocalizedString("AWS Access Key [$AWS_ACCESS_KEY_ID]", comment: "Access key usage")
    let sUsage = NSLocalizedString("AWS Secret Key [$AWS_SECRET_ACCESS_KEY]", comment: "Secret key usage")
    return (
        commandParser.add(option: "--amazonec2-access-key", shortName: "-k", kind: String.self, usage: akUsage, completion: ShellCompletion.none),
        commandParser.add(option: "--amazonec2-secret-key", shortName: "-s", kind: String.self, usage: sUsage, completion: ShellCompletion.none)
    )
}

func unitTest(for commandParser: ArgumentParser) -> OptionArgument<Bool>{
    let usage = NSLocalizedString("If specified will print commands which will be run rather than actually performing those commands", comment: "Unit test usage")
    return commandParser.add(option: "--unit-test", shortName: nil, kind: Bool.self, usage: usage, completion: ShellCompletion.values([(value: "true", description: "The value for a boolean true"), (value: "false", description: "The value for a boolean false")]))
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
        clusterCommand(for: argumentParser),
        machineCommand(for: argumentParser)
    ]
}


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

func machineCreateCommand(for argumentParser: ArgumentParser) -> Command {
    let name = "create"
    let commandParser = argumentParser.add(
        subparser: name,
        overview: NSLocalizedString("Create a machine.",
                                    comment: "Machine command overview")
    )
//    let (awsAccessKey, awsSecretKey) = awsAccessArguments(for: commandParser)
//    let machineName = namesArgument(for: commandParser)
    let unit = unitTest(for: commandParser)
    let remainingArgumentsOptional = remainingArguments(for: commandParser)
    return Command(
        name: name,
        run: { (arguments) in
            let isUnitTest = arguments.get(unit) ?? false
            guard let remainingArguments = arguments.get(remainingArgumentsOptional) else {
                throw ArgumentParserError.expectedArguments(commandParser, ["docker-machine_arguments"])
            }
            print( try createMachine(using: remainingArguments, isUnitTest: isUnitTest) )
//            print(isUnitTest ? "true" : "false")
//            let config = MachineConfig(
//            createMachines(withNames: <#T##[String]#>, andConfig: <#T##MachineConfig#>)
    })
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
