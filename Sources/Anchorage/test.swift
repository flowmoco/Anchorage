import Foundation

public struct Driver: Encodable, Decodable {
    public var name: String
    public var region: String
    public var rootSize: Int
    public var availabilityZone: String
    public var image: String
    public var user: String
    
}

public struct DefaultConfig: Encodable, Decodable {
    public var configVersion: Int
    public var driver: Driver
}

public func jsonEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    if #available(OSX 10.12, *) {
        encoder.dateEncodingStrategy = .iso8601
    } else {
        // Fallback on earlier versions
        encoder.dateEncodingStrategy = .deferredToDate
    }
    encoder.dataEncodingStrategy = .base64
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.nonConformingFloatEncodingStrategy = .throw
    return encoder
}

public func jsonDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dataDecodingStrategy = .base64
    if #available(OSX 10.12, *) {
        decoder.dateDecodingStrategy = .iso8601
    } else {
        decoder.dateDecodingStrategy = .deferredToDate
    }
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.nonConformingFloatDecodingStrategy = .throw
    return decoder
}

public func save(defaultConfig: DefaultConfig, to url: URL) throws {
    let data = try jsonEncoder().encode(defaultConfig)
    try data.write(to: url)
}

public func defaultConfig(from url: URL) throws -> DefaultConfig {
    return try jsonDecoder().decode(DefaultConfig.self, from: Data(contentsOf: url))
}

public func defaultConfig(with fileManager: FileManager) throws -> DefaultConfig {
    return try defaultConfig(from: try defaultConfigFile(with: fileManager))
}

enum ConfigErrors: Error {
    case directoryAlreadyExistsat(path: String)
}

func initialDefaultConfig() -> DefaultConfig {
    let driver = Driver(name: "amazonec2", region: "eu-west-2", rootSize: 100, availabilityZone: "a", image: "ami-0d9ba70fd9e495233", user: "admin")
    return DefaultConfig(configVersion: 1, driver: driver)
}

public func defaultConfigFile(with fileManager: FileManager) throws -> URL {
    let defaultConfigFileURL = try anchorageDirectory(with: fileManager).appendingPathComponent("defaultConfig.json")
    if !fileManager.fileExists(atPath: defaultConfigFileURL.path) {
        try save(defaultConfig: initialDefaultConfig(), to: defaultConfigFileURL)
    }
    return defaultConfigFileURL
}

public func anchorageDirectory(with fileManager: FileManager) throws -> URL {
    let anchorageDir: URL
    if #available(OSX 10.12, *) {
        anchorageDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".anchorage")
    } else {
        anchorageDir = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent(".anchorage")
    }
    return try createDirectory(at: anchorageDir.path, ifNotExistsWith: fileManager)
}

public func createDirectory(at path: String, ifNotExistsWith fileManager: FileManager) throws -> URL {
    var isDir : ObjCBool = false
    if fileManager.fileExists(atPath: path, isDirectory:&isDir) {
        if isDir.boolValue {
            // file exists and is a directory
            return URL(fileURLWithPath: path, isDirectory: true)
        } else {
            // file exists and is not a directory
            throw ConfigErrors.directoryAlreadyExistsat(path: path)
        }
    } else {
        try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        return URL(fileURLWithPath: path, isDirectory: true)
    }
}
