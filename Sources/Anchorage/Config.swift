import Foundation

public struct Driver: Encodable, Decodable {
    
    public var region: String
    public var rootSize: Int
    public var availabilityZone: String
    public var image: String
    public var user: String
    
    public var accessKey: String?
    public var secretKey: String?
    
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
    #if os(Linux)
    
    #else
        encoder.keyEncodingStrategy = .convertToSnakeCase
    #endif
    encoder.nonConformingFloatEncodingStrategy = .throw
    return encoder
}

func dateDecodingStratergy() -> JSONDecoder.DateDecodingStrategy {
    if #available(OSX 10.12, *) {
        return .iso8601
    } else {
        return .deferredToDate
    }
}

public func jsonDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dataDecodingStrategy = .base64
    decoder.dateDecodingStrategy = dateDecodingStratergy()
    #if os(Linux)
    
    #else
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    #endif
    decoder.nonConformingFloatDecodingStrategy = .throw
    return decoder
}

public func save<T>(encodable: T, to url: URL) throws where T : Encodable {
    let data = try jsonEncoder().encode(encodable)
    try data.write(to: url)
}

func retrieve<T>(decodableType: T.Type, from url: URL) throws -> T where T : Decodable {
    return try jsonDecoder().decode(decodableType, from: Data(contentsOf: url))
}

public func defaultConfig(from url: URL) throws -> MachineConfig {
    return try retrieve(decodableType: MachineConfig.self, from: url)
}

public func defaultConfig(with fileManager: FileManager) throws -> MachineConfig {
    return try defaultConfig(from: try defaultConfigFile(with: fileManager))
}

enum ConfigErrors: Error {
    case directoryAlreadyExistsat(path: String)
}

func initialDefaultConfig() -> MachineConfig {
    let driver = Driver(region: "eu-west-2", rootSize: 100, availabilityZone: "a", image: "ami-0d9ba70fd9e495233", user: "admin", accessKey: nil, secretKey: nil)
    return MachineConfig(configVersion: 1, driverName: "amazonec2", driver: driver, engineStorageDriver: "overlay2")
}



public func defaultConfigFile(with fileManager: FileManager) throws -> URL {
    let defaultConfigFileURL = try anchorageDirectory(with: fileManager).appendingPathComponent(MachineConfig.defaultConfigFileName)
    if !fileManager.fileExists(atPath: defaultConfigFileURL.path) {
        try save(encodable: initialDefaultConfig(), to: defaultConfigFileURL)
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

public func listConfigFolders(within url: URL, using fileManager: FileManager) throws -> [String] {
    let urls = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants])
    return try urls.compactMap { (url) -> String? in
        let vals = try url.resourceValues(forKeys: [.isDirectoryKey])
        if vals.isDirectory == true && fileManager.fileExists(atPath: url.appendingPathComponent("config").appendingPathExtension("json").path){
            return url.lastPathComponent
        } else {
            return nil
        }
    }
}
