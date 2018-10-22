//
//  Machine.swift
//  Anchorage_CLI
//
//  Created by Robert Harrison on 22/10/2018.
//

import Foundation
import Utility
import Basic
import Anchorage

enum MachineArgument: CaseIterable {
    case amazonec2AccessKey
    case amazonec2SecretKey
    
    var argumentName: String {
        switch self {
        case .amazonec2AccessKey:
            return "--amazonec2-access-key"
        case .amazonec2SecretKey:
            return "--amazonec2-secret-key"
        }
    }
    
    var argumentShortName: String?{
        switch self {
        case .amazonec2AccessKey:
            return "-k"
        case .amazonec2SecretKey:
            return "-s"
        }
    }
    
    func argument(for commandParser: ArgumentParser) -> Any {
        switch self {
        case .amazonec2AccessKey:
            return commandParser.add(
                option: self.argumentName, shortName: self.argumentShortName, kind: String.self,
                usage: NSLocalizedString("AWS Access Key [$AWS_ACCESS_KEY_ID]", comment: "Access key usage"),
                completion: ShellCompletion.none
            )
        case .amazonec2SecretKey:
            return commandParser.add(
                option: self.argumentName, shortName: self.argumentShortName, kind: String.self,
                usage: NSLocalizedString("AWS Secret Key [$AWS_SECRET_ACCESS_KEY]", comment: "Secret key usage"),
                completion: ShellCompletion.none
            )
        }
    }
    
    static func arguments(for commandParser: ArgumentParser) -> [MachineArgument: Any] {
        return MachineArgument.allCases.reduce(into: [MachineArgument: Any](), { (result, arg) in
            result[arg] = arg.argument(for: commandParser)
        })
    }
    
    public static func set(machineArguments args: [MachineArgument: Any], on config: MachineConfig, for result: ArgumentParser.Result) throws -> MachineConfig {
        var outConfig = config
        args.forEach { (arg, value) in
            arg.set(machineArgument: value, on: &outConfig, for: result)
        }
        return outConfig
    }
    
    func set(machineArgument arg: Any, on config: inout MachineConfig, for result: ArgumentParser.Result) {
        switch self {
        case .amazonec2AccessKey:
            guard let s = result.get(arg as! OptionArgument<String>) else { return }
            config.driver.accessKey = s
        case .amazonec2SecretKey:
            guard let s = result.get(arg as! OptionArgument<String>) else { return }
            config.driver.secretKey = s
        }
    }
    
    func argumentsList(for config: MachineConfig) -> [String]? {
        switch self {
        case .amazonec2AccessKey:
            guard let s = config.driver.accessKey else { return nil }
            return [self.argumentName, s]
        case .amazonec2SecretKey:
            guard let s = config.driver.secretKey else { return nil }
            return [self.argumentName, s]
        }
    }
    
    static func argumentsList(for config: MachineConfig) -> [String] {
        return self.allCases.reduce(into: [String](), { (result, arg) in
            guard let s = arg.argumentsList(for: config) else { return }
            result.append(contentsOf: s)
        })
    }
}



func defaultConfig(forCluster cluster: String, using fileManager: FileManager) throws -> MachineConfig {
    if let config = try Cluster.defaultMachineConfig(with: cluster, using: fileManager) {
        return config
    }
    return try defaultConfig(with: fileManager)
}

func config(for machineArguments: [MachineArgument: Any], andCluster cluster: String, using fileManager: FileManager, for result: ArgumentParser.Result) throws -> MachineConfig {
    return try MachineArgument.set(machineArguments: machineArguments, on: defaultConfig(forCluster: cluster, using: fileManager), for: result)
}

func config(for machineArguments: [MachineArgument: Any], using fileManager: FileManager, for result: ArgumentParser.Result) throws -> MachineConfig {
    return try MachineArgument.set(machineArguments: machineArguments, on: try defaultConfig(with: fileManager), for: result)
}
