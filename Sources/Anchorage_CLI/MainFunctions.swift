//
//  Entrypoint.swift
//  Anchorage-CLI
//
//  Created by Robert Harrison on 15/10/2018.
//

import Foundation
import Anchorage
import Utility
import Basic

func run(commands: [Command], for commandParser: ArgumentParser, giving result: ArgumentParser.Result) throws {
    guard let subparser = result.subparser(commandParser) else {
        commandParser.printUsage(on: stderrStream)
        exit(127)
    }
    
    let toRun = commands.compactMap { $0.name == subparser ? $0 : nil }
    
    if toRun.isEmpty {
        commandParser.printUsage(on: stderrStream)
        exit(127)
    } else {
        try toRun.forEach { (command) in
            try command.run(result)
        }
    }
}

public func main(withArguments arguments: [String], commandName: String, overview: String) {
    
    let argumentParser = ArgumentParser(commandName: commandName, usage: "<COMMAND> [options]", overview: overview, seeAlso: nil)
    
    let commands = rootCommands(for: argumentParser)
    
    do {
        
        let result = try argumentParser.parse(prepare(arguments: arguments))
        try run(commands: commands, for: argumentParser, giving: result)
        
    } catch ArgumentParserError.expectedArguments(let parser, let name) {
        print(
            errorMessage: "Missing expected arguments: [" +
            name.joined(separator: ", ") + "]\n"
        )
        parser.printUsage(on: stderrStream)
        exit(1)
    } catch let error as ArgumentParserError {
        handle(error: error)
    } catch let error {
        handle(error: error)
    }
}
