//
//  File.swift
//  Anchorage
//
//  Created by Robert Harrison on 10/10/2018.
//

import Foundation

enum MachineErrors: Error, LocalizedError {
    case invalid(name: String)
    
    var localizedDescription: String {
        switch self {
        case .invalid(let name):
            return String(format: NSLocalizedString("'%@' is not a valid machine name, which should only contain the following characers: [a-zA-Z0-9\\-]", comment: "Invalid name"), name)
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
    
    let isUnit: Bool
    public let machineName: String
    
    public init(withName name: String, andConfig config: MachineConfig, isUnit: Bool) {
        let homeDirURL: URL
        if #available(OSX 10.12, *) {
            let fileManager = FileManager()
            homeDirURL = fileManager.homeDirectoryForCurrentUser
        } else {
            homeDirURL = URL(fileURLWithPath: NSHomeDirectory())
        }
        self.isUnit = isUnit
        self.machineName = name
        super.init(
            commands: [
                "docker-machine", "create"
            ] + MachineArgument.argumentsList(for: config) + [ name ],
            currentDirectory: homeDirURL)
        self.name = "CreateMachineOperation(withName: \(name))"
    }
    
    public override func main() {
        if isCancelled {
            return
        }
        if isUnit {
            guard let commands = process.arguments else { return }
            guard let data = commands.joined(separator: " ").data(using: .utf8) else { return }
            let fileHandle = self.standardOutputPipe.fileHandleForWriting
            fileHandle.write(data)
            fileHandle.closeFile()
            self.standardErrorPipe.fileHandleForWriting.closeFile()
            
            self.state = .finished
        } else {
            super.main()
        }
    }
    
    public override var terminationStatus: Int32 {
        if isUnit {
            return 0
        }
        return super.terminationStatus
    }

}

func currentDirectory(using: FileManager = FileManager.default) -> URL {
    return URL(fileURLWithPath: using.currentDirectoryPath)
}
