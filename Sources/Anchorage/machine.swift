//
//  File.swift
//  Anchorage
//
//  Created by Robert Harrison on 10/10/2018.
//

import Foundation

enum MachineErrors: Error {
    case invalid(name: String)
    
    var localizedDescription: String {
        switch self {
        case .invalid(let name):
            return "foo \(name)"
//            return String(format: NSLocalizedString("'%@' is not a valid machine name, which should only contain the following characers: [a-zA-Z0-9\\-]'", comment: "Invalid name"), arguments: name)
        }
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

public func perform(command: String) throws -> String {
    return "output"
}
