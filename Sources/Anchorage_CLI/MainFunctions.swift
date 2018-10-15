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

public func main(withArguments arguments: [String], commandName: String, overview: String) {
    do {
        let argumentParser = ArgumentParser(commandName: commandName, usage: "<COMMAND> [options]", overview: overview, seeAlso: nil)
        
        let clusterParser = argumentParser.add(subparser: "cluster", overview: NSLocalizedString("Create, destroy and manage clusters.", comment: "Cluster command overview"))
        let clusterCreateParser = clusterParser.add(subparser: "create", overview: NSLocalizedString("Create new clusters.", comment: "Create command overview"))
        let clusterRemoveParser = clusterParser.add(subparser: "rm", overview: NSLocalizedString("Delete the specified cluster", comment: "rm command overview"))
        let clusterListParser = clusterParser.add(subparser: "ls", overview: NSLocalizedString("List all managed clusters.", comment: "List command overview"))
        
        let clusterCreateNames = clusterCreateParser.add(positional: "name", kind: [String].self, optional: false, strategy: .oneByOne, usage: "Name argument usage", completion: .none)
        
        let clusterRemoveNames = clusterRemoveParser.add(positional: "name", kind: [String].self, optional: false, strategy: .oneByOne, usage: "Name argument usage", completion: .none)
        
        // add subcommands
        
        let result = try argumentParser.parse(prepare(arguments: arguments))
        
        if let subparser = result.subparser(argumentParser) {
            print("Got here 1")
            switch subparser {
            case "cluster":
                print("Got this far")
                if let subparser = result.subparser(clusterParser) {
                    if subparser == "ls" {
                        print(
                            try Cluster.list(using: FileManager.default).joined(separator: "\t")
                        )
                    }
                    print(subparser)
                    return
                }
            default:
                break
            }
        }
        
        argumentParser.printUsage(on: stderrStream)
        exit(1)
        
    } catch let error as ArgumentParserError {
        handle(error: error)
    } catch let error {
        handle(error: error)
    }
}
