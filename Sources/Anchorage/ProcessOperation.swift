//
//  ProcessOperation.swift
//  Anchorage
//
//  Created by Robert Harrison on 23/10/2018.
//

import Foundation
import Dispatch

public class ProcessOperation: AsyncOperation {
    
    public static var defaultQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        queue.name = "ProcessOperation.defaultQueue"
        return queue
    }()
    
    public init(commands: [String],
                isUnit: Bool,
                currentDirectory: URL? = nil,
                environment: [String: String]? = nil) {
        process = Process()
        process.arguments = commands
        process.environment = environment ?? ProcessInfo.processInfo.environment
        process.standardError = Pipe()
        process.standardOutput = Pipe()
        
        if #available(OSX 10.13, *) {
            process.currentDirectoryURL = currentDirectory ?? FileManager().homeDirectoryForCurrentUser
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        } else {
            process.currentDirectoryPath = currentDirectory?.path ?? NSHomeDirectory()
            process.launchPath = "/usr/bin/env"
        }
        self.isUnit = isUnit
        super.init()
        name = "Process " + commands.joined(separator: " ")
    }
    
    public let process: Process
    public var standardErrorPipe: Pipe {
        return process.standardError as! Pipe
    }
    public var standardOutputPipe: Pipe {
        return process.standardOutput as! Pipe
    }
    
    public var error: Error?
    let isUnit: Bool
    
    public var terminationStatus: Int32 {
        if isUnit {
            return 0
        }
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
        if isUnit {
            self.state = .executing
            guard let commands = process.arguments else {
                self.state = .finished
                return
            }
            let commandString = commands.joined(separator: " ")
            writeAndClose(string: commandString, toFileHandle: self.standardOutputPipe.fileHandleForWriting)
            writeAndClose(string: nil, toFileHandle: self.standardErrorPipe.fileHandleForWriting)
            self.state = .finished
        } else {
            self.state = .executing
            
            process.qualityOfService = self.qualityOfService
            
            process.terminationHandler = { [weak self] (process) in
                self?.processTerminated()
            }
            
            do {
                
                #if os(Linux)
                process.launch()
                #else
                if #available(OSX 10.13, *) {
                    try process.run()
                } else {
                    process.launch()
                }
                #endif
            } catch {
                self.error = error
            }
        }
    }
    
    public func processTerminated(){
        self.state = .finished
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
    
    public func printOutput(){
        if let output = self.standardOutput, !output.isEmpty {
            print(output)
        }
    }
    
    public func printError(){
        if let error = self.standardError, !error.isEmpty {
            print(errorMessage: error)
        }
    }
    
    public func printOutputOperation(and: (()->Void)? = nil) -> BlockOperation {
        return afterOp {
            self.printOutput()
            and?()
        }
    }
    
    public func printErrorOperation(and: (()->Void)? = nil) -> BlockOperation {
        return afterOp {
            self.printError()
            and?()
        }
    }
    
    public func afterOp(_ completionBlock: @escaping () -> Void) -> BlockOperation {
        let op = BlockOperation(block: completionBlock)
        op.addDependency(self)
        return op
    }
}
