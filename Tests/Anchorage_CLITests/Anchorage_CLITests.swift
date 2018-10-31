import XCTest
import class Foundation.Bundle
@testable import Anchorage_CLI
import Anchorage

final class Anchorage_CLITests: XCTestCase {
    
    func run(commands: [String], exitCode: Int32 = 0) throws -> (String, String) {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        
        let fooBinary = productsDirectory.appendingPathComponent("anchor")
        
        let process = Process()
        process.arguments = commands
        if #available(OSX 10.13, *) {
            process.executableURL = fooBinary
        } else {
            process.launchPath = fooBinary.path
        }
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        if #available(OSX 10.13, *) {
            try process.run()
        } else {
            process.launch()
        }
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        let errorOutput = String(data: errorData, encoding: .utf8)
        //        XCTAssertEqual(errorOutput, "")
        XCTAssertEqual(process.terminationStatus, exitCode)
        return (output!, errorOutput!)
        //XCTAssertTrue( output!.contains("command is used to manage a docker swarm cluster"))
    }
    
    func testEmptyList() throws {
        let (output, error) = try run(commands: ["cluster", "ls"])
        XCTAssertEqual(output, "")
        XCTAssertEqual(error, "")
    }
    
    func testEmptyCreate() throws {
        let (output, error) = try run(commands:["cluster", "create"], exitCode: 1)
        XCTAssertEqual(output, "")
        XCTAssertTrue(error.contains("Missing expected arguments"), "Expected to recieve expected arguments string")
        Cluster.Argument.allCases.forEach { (arg) in
            XCTAssertTrue(error.contains(arg.argumentName), "Expected to recieve usage for \(arg.argumentName)")
        }
    }
    
    func testMachineCreateCommandHelp() throws {
        let (output, error) = try run(commands: ["machine", "create", "-h"], exitCode: 0)
        XCTAssertEqual(error, "")
        //        XCTAssertEqual(output, "")
        MachineArgument.allCases.forEach { (arg) in
            XCTAssertTrue(output.contains(arg.argumentName), "Should show argument \(arg.argumentName) in help output")
        }
        XCTAssertTrue(output.contains("OVERVIEW"), "Should show command overview in output")
        XCTAssertTrue(output.contains("--unit-test"), "Should show create command in output")
        XCTAssertTrue(output.contains("Create a machine"), "Should show create command in output")
    }
    
    func testClusterCreateCommand() throws {
        let (output, error) = try run(commands: ["cluster", "create", "test", "--unit-test", "--swarm-managers", "1"], exitCode: 0)
        XCTAssertEqual(error, "")
        XCTAssertEqual(output, """
docker-machine create test-swarm-manager-1
Created machine test-swarm-manager-1
Cluster created successfully!

""")
    }

    /// Returns path to the built products directory.
    var productsDirectory: URL {
      #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
      #else
        return Bundle.main.bundleURL
      #endif
    }

    static var allTests = [
      ("testEmptyList", testEmptyList),
    ]
}
