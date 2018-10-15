//
//  Entrypoint.swift
//  Anchorage-CLI
//
//  Created by Robert Harrison on 15/10/2018.
//

import Foundation
import Utility
import Basic

public func main(withArguments arguments: [String], commandName: String, overview: String) {
    do {
        let argumentParser = ArgumentParser(commandName: commandName, usage: "<COMMAND> [options]", overview: overview, seeAlso: nil)
        
        // add subcommands
        
        let result = try argumentParser.parse(prepare(arguments: arguments))
        
        guard let subparser = result.subparser(argumentParser) else {
            argumentParser.printUsage(on: stderrStream)
            exit(1)
        }
        
    } catch let error as ArgumentParserError {
        handle(error: error)
    } catch let error {
        handle(error: error)
    }
}
