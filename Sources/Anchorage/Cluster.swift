//
//  Cluster.swift
//  Anchorage
//
//  Created by Robert Harrison on 15/10/2018.
//

import Foundation

public struct Cluster: Encodable, Decodable {
    
    public enum Argument: CaseIterable {
        case swarmManagers
        case swarmWorkers
        case ceph
        
        public var argumentName: String {
            switch self {
            case .swarmManagers:
                return "--swarm-managers"
            case .swarmWorkers:
                return "--swarm-workers"
            case .ceph:
                return "--ceph"
            }
        }
        
        public var argumentShortName: String?{
            switch self {
            case .swarmManagers:
                return "-m"
            case .swarmWorkers:
                return "-w"
            case .ceph:
                return "-c"
            }
        }
        
        func argumentsList(for cluster: Cluster) -> [String]? {
            switch self {
            case .swarmManagers, .swarmWorkers, .ceph:
                return nil
            }
        }
        
        static func argumentsList(for cluster: Cluster) -> [String] {
            return self.allCases.reduce(into: [String](), { (result, arg) in
                guard let s = arg.argumentsList(for: cluster) else { return }
                result.append(contentsOf: s)
            })
        }
    }
    
    public let name: String
    
    public var managers: [String] = []
    public var workers: [String] = []
    
    public init(name: String) throws {
        self.name = try valid(identifier: name)
    }
    
    public static func list(using fileManager: FileManager) throws -> [String] {
        let url = try clustersDirectory(using: fileManager)
        return try listConfigFolders(within: url, using: fileManager)
    }
    
    public static func with(name: String, using fileManager: FileManager) throws -> Cluster {
        let url = try clusterConfigFile(with: name, using: fileManager, create: false)
        return try retrieve(decodableType: Cluster.self, from: url)
    }
    
    public func save(using fileManager: FileManager) throws {
        let url = try type(of: self).clusterConfigFile(with: name, using: fileManager, create: true)
        try Anchorage.save(encodable: self, to: url)
    }
    
    public func delete(using fileManager: FileManager) throws {
        try fileManager.removeItem(at: type(of: self).clusterDirectory(with: self.name, using: fileManager))
    }
    
    public static func exists(with name: String, using fileManager: FileManager) throws -> Bool {
        return fileManager.fileExists(atPath: try clusterConfigFile(with: name, using: fileManager).path)
    }
    
    static func clusterConfigFile(with name: String, using fileManager: FileManager, create: Bool = false) throws -> URL {
        let dir = try clusterDirectory(with: name, using: fileManager)
        if create {
            _ = try createDirectory(at: dir.path, ifNotExistsWith: fileManager)
        }
        return dir.appendingPathComponent("config").appendingPathExtension("json")
    }
    
    static func defaultMachineConfigFile(with name: String, using fileManager: FileManager) throws -> URL? {
        let configFileURL = try clusterDirectory(with: name, using: fileManager).appendingPathComponent(MachineConfig.defaultConfigFileName, isDirectory: false)
        if fileManager.fileExists(atPath: configFileURL.path) {
            return configFileURL
        }
        return nil
    }
    
    public static func defaultMachineConfig(with name: String, using fileManager: FileManager) throws -> MachineConfig? {
        guard let configFileURL = try Cluster.defaultMachineConfigFile(with: name, using: fileManager) else {
            return nil
        }
        return try retrieve(decodableType: MachineConfig.self, from: configFileURL)
    }
    
    static func clusterDirectory(with name: String, using fileManager: FileManager) throws -> URL {
        return try clustersDirectory(using: fileManager).appendingPathComponent(name, isDirectory: true)
    }
    
    static func clustersDirectory(using fileManager: FileManager) throws -> URL {
        return try anchorageDirectory(with: fileManager).appendingPathComponent("clusters", isDirectory: true)
    }
}
