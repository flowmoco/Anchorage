//
//  File.swift
//  Anchorage
//
//  Created by Robert Harrison on 10/10/2018.
//

import Foundation

struct Machine: Encodable, Decodable {
    
    let ConfigVersion: Int
    let Driver: Machine.Driver
    let HostOptions: Machine.HostOptions
    let Name: String
    
    struct Driver: Encodable, Decodable {
        let PrivateIPAddress: String
    }
    
    struct HostOptions: Encodable, Decodable {
        let EngineOptions: HostOptions.EngineOptions
        
        struct EngineOptions: Encodable, Decodable {
            let TlsVerify: Bool
        }
    }
    
    static func named(_ name: String, using fileManager: FileManager) -> Machine? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStratergy()
        decoder.dataDecodingStrategy = .base64
        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.nonConformingFloatDecodingStrategy = .throw
        guard let data = try? Data(contentsOf: configFile(forMachine: name, using: fileManager)) else {
            return nil
        }
        return try? decoder.decode(Machine.self, from: data)
    }
    
    static func configFile(forMachine named: String, using fileManager: FileManager) -> URL {
        let home: URL
        if #available(OSX 10.12, *) {
            home = fileManager.homeDirectoryForCurrentUser
        } else {
            home = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        }
        return home.appendingPathComponent(".docker/machine/machines", isDirectory: true).appendingPathComponent(named, isDirectory: true).appendingPathComponent("config.json", isDirectory: false)
    }
}





enum MachineErrors: Error, LocalizedError {
    case invalid(name: String)
    
    var localizedDescription: String {
        switch self {
        case .invalid(let name):
            return name.withCString { (name) -> String in
                return String(format: NSLocalizedString("'%s' is not a valid machine name, which should only contain the following characers: [a-zA-Z0-9\\-]", comment: "Invalid name"), name)
            }
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
    public var driverName: String
    public var driver: Driver
    public var engineStorageDriver: StorageDriver?
    
    static let defaultConfigFileName = "defaultMachineConfig.json"
}

public enum MachineArgument: CaseIterable {
    case amazonec2AccessKey
    case amazonec2SecretKey
    
    public var argumentName: String {
        switch self {
        case .amazonec2AccessKey:
            return "--amazonec2-access-key"
        case .amazonec2SecretKey:
            return "--amazonec2-secret-key"
        }
    }
    
    public var argumentShortName: String?{
        switch self {
        case .amazonec2AccessKey:
            return "-k"
        case .amazonec2SecretKey:
            return "-s"
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

public func valid(identifier: String) throws -> String {
    if let _ = identifier.trimmingCharacters(in: .whitespacesAndNewlines).range(of: "^[a-zA-Z\\-0-9]{3,128}$", options: .regularExpression, range: nil, locale: nil) {
        return identifier
    } else {
        throw MachineErrors.invalid(name: identifier)
    }
}

//public func createMachine(using arguments: [String], isUnitTest: Bool = false) throws -> String {
//    let commands = ["docker-machine", "create"] + arguments
//    if isUnitTest {
//        return commands.joined(separator: " ")
//    }
//    let p = try process(commands: commands, currentDirectory: currentDirectory(), environment: nil, qualityOfService: .userInitiated)
//    return try wait(forProcess: p)
//}

public class CreateMachineOperation: ProcessOperation {
    
    public let machineName: String
    
    public init(withName name: String, andConfig config: MachineConfig, isUnit: Bool) {
        self.machineName = name
        super.init(
            commands: [
                "docker-machine", "create"
                ] + MachineArgument.argumentsList(for: config) + [ name ], isUnit: isUnit)
    }    

}

func environmentVariables(forDockerMachineOutput output: String) -> [String: String] {
    let trimSet = CharacterSet(charactersIn: "\"' \n")
    return output.split(separator: "\n").reduce(into: [String: String](), { (result, line) in
        let commands = line.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        if commands.count < 2 || commands[0] != "export" {
            return
        }
        let lineSeperated = commands[1].split(separator: "=", maxSplits: 1, omittingEmptySubsequences: true)
        if lineSeperated.count <= 1 {
            return
        }
        let name = lineSeperated[0]
        let value = lineSeperated[1].trimmingCharacters(in: trimSet)
        if value.isEmpty {
            return
        }
        result[String(name)] = value
    })
}

func currentDirectory(using: FileManager = FileManager.default) -> URL {
    return URL(fileURLWithPath: using.currentDirectoryPath)
}
