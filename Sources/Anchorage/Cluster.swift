//
//  Cluster.swift
//  Anchorage
//
//  Created by Robert Harrison on 15/10/2018.
//

import Foundation

struct Cluster: Encodable, Decodable {
    let name: String
    
    init(name: String) throws {
        self.name = try valid(identifier: name)
    }
    
    static func with(name: String, using fileManager: FileManager) throws -> Cluster {
        let url = try clusterConfigFile(with: name, using: fileManager, create: false)
        return try retrieve(decodableType: Cluster.self, from: url)
    }
    
    func save(using fileManager: FileManager) throws {
        let url = try type(of: self).clusterConfigFile(with: name, using: fileManager, create: true)
        try Anchorage.save(encodable: self, to: url)
    }
    
    func delete(using fileManager: FileManager) throws {
        try fileManager.removeItem(at: type(of: self).clusterDirectory(with: self.name, using: fileManager))
    }
    
    static func exists(with name: String, using fileManager: FileManager) throws -> Bool {
        return fileManager.fileExists(atPath: try clusterConfigFile(with: name, using: fileManager).path)
    }
    
    static func clusterConfigFile(with name: String, using fileManager: FileManager, create: Bool = false) throws -> URL {
        let dir = try clusterDirectory(with: name, using: fileManager)
        if create {
            _ = try createDirectory(at: dir.path, ifNotExistsWith: fileManager)
        }
        return dir.appendingPathComponent("config").appendingPathExtension("json")
    }
    
    static func clusterDirectory(with name: String, using fileManager: FileManager) throws -> URL {
        return try clustersDirectory(using: fileManager).appendingPathComponent(name, isDirectory: true)
    }
    
    static func clustersDirectory(using fileManager: FileManager) throws -> URL {
        return try anchorageDirectory(with: fileManager).appendingPathComponent("clusters", isDirectory: true)
    }
}
