//
//  Cluster.swift
//  Anchorage
//
//  Created by Robert Harrison on 15/10/2018.
//

import Foundation

public struct Cluster: Encodable, Decodable {
    
    public enum Errors: Error {
        case swarmRequiresManagers
        
        public var localizedDescription: String {
            switch self {
            case .swarmRequiresManagers:
                return NSLocalizedString("Unable to create cluster with less than 1 swarm manager.", comment: "Cluster Error")
            }
        }
    }
    
    public enum Argument: CaseIterable {
        case swarmManagers
        case swarmWorkers
        case cephNodes
        
        public var argumentName: String {
            switch self {
            case .swarmManagers:
                return "--swarm-managers"
            case .swarmWorkers:
                return "--swarm-workers"
            case .cephNodes:
                return "--ceph-nodes"
            }
        }
        
        public var argumentShortName: String?{
            switch self {
            case .swarmManagers:
                return "-m"
            case .swarmWorkers:
                return "-w"
            case .cephNodes:
                return "-c"
            }
        }
        
        func argumentsList(for cluster: Cluster) -> [String]? {
            switch self {
            case .swarmManagers, .swarmWorkers, .cephNodes:
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
    
    public enum Kinds: String, Encodable, Decodable, CaseIterable {
        case swarmManager = "swarm-manager"
        case swarmWorker = "swarm-worker"
        case cephNode = "ceph-node"
    }
    
    public let name: String
    
    public var nodes: [Kinds: [String]] = [:]
    
    public let initialNodeCounts: [Kinds: Int]
    
    public init(name: String, initialSwarmManagers: Int? = nil, initialSwarmWorkers: Int? = nil, initialCephNodes: Int? = nil) throws {
        self.name = try valid(identifier: name)
        self.initialNodeCounts = Kinds.allCases.reduce(into: [Kinds: Int](), { (out, kind) in
            switch kind {
            case .swarmManager:
                out[kind] = initialSwarmManagers ?? 0
            case .swarmWorker:
                out[kind] = initialSwarmWorkers ?? 0
            case .cephNode:
                out[kind] = initialCephNodes ?? 0
            }
        })
        
        if let workers = initialSwarmWorkers, workers > 0 {
            guard let managers = initialSwarmManagers, managers > 0 else {
                throw Errors.swarmRequiresManagers
            }
        }
    }
    
    public func initialNames(for kind: Kinds) -> [String] {
        guard let number = initialNodeCounts[kind] else {
            return []
        }
        return newNames(quantity: number, forNodeKind: kind)
    }
    
    public func newNames(quantity number: Int, forNodeKind kind: Kinds) -> [String] {
        let minInt: Int
        if let nodes = self.nodes[kind] {
            minInt = nodes.reduce(1) { (prev, name) -> Int in
                guard let numberString = name.components(separatedBy: CharacterSet.decimalDigits.inverted).last, let number = Int(numberString), number >= prev else {
                    return prev
                }
                return number + 1
            }
        } else {
            minInt = 1
        }
        return (minInt..<(minInt + number)).map({ (n) -> String in
            return "\(self.name)-\(kind.rawValue)-\(n)"
        })
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
