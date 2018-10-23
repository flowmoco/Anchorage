//
//  ProcessOperation.swift
//  Anchorage
//
//  Created by Robert Harrison on 23/10/2018.
//

import Foundation

public class ProcessOperation: AsyncOperation {
    
    public static var defaultQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        queue.name = "ProcessOperation.defaultQueue"
        return queue
    }()
    
    init(commands: [String],
                 currentDirectory: URL,
                 environment: [String: String]? = nil) {
        process = Process()
        process.arguments = commands
        process.environment = environment ?? ProcessInfo.processInfo.environment
        process.standardError = Pipe()
        process.standardOutput = Pipe()
        
        if #available(OSX 10.13, *) {
            process.currentDirectoryURL = currentDirectory
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        } else {
            process.currentDirectoryPath = currentDirectory.path
            process.launchPath = "/usr/bin/env"
        }
        
    }
    
    public let process: Process
    public var standardErrorPipe: Pipe {
        return process.standardError as! Pipe
    }
    public var standardOutputPipe: Pipe {
        return process.standardOutput as! Pipe
    }
    
    public var error: Error?
    
    public var terminationStatus: Int32 {
        return process.terminationStatus
    }
    
    public var terminationReason: Process.TerminationReason {
        return process.terminationReason
    }
    
    public func output() throws -> String {
        if let error = self.error {
            throw error
        }
        return (self.standardOutput ?? "") + (self.standardError ?? "")
    }
    
    override public func main() {
        self.state = .executing
        
        process.qualityOfService = self.qualityOfService
        
        process.terminationHandler = { [weak self] (process) in
            self?.state = .finished
        }
        
        do {
            if #available(OSX 10.13, *) {
                try process.run()
            } else {
                process.launch()
            }
        } catch {
            self.error = error
        }
    }
    
    public func startAndWait() -> ProcessOperation {
        if self.isCancelled || self.isFinished {
            return self
        }
        if !self.isExecuting {
            start()
        }
        self.process.waitUntilExit()
        return self
    }
    
    override public func cancel() {
        process.terminate()
        super.cancel()
    }
    
    public var standardOutput: String? {
        return String(bytes: self.standardOutputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
    }
    
    public var standardError: String? {
        return String(bytes: self.standardErrorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
    }
}
