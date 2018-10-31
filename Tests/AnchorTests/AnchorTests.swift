import XCTest
import class Foundation.Bundle

final class AnchorTests: XCTestCase {

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

    func testMachineCommand() throws {
        let (output, error) = try run(commands: ["machine"], exitCode: 127)
        XCTAssertEqual(output, "")
        XCTAssertTrue(error.contains("OVERVIEW"), "Should show command overview in error output")
        XCTAssertTrue(error.contains("create"), "Should show create command in error output")
    }
    
    func testMachineCommandBadInput() throws {
        let (output, error) = try run(commands: ["machine", "foo"], exitCode: 1)
        XCTAssertEqual(output, "")
        XCTAssertTrue(error.contains("expected arguments"), "Should show expected arguments in error output")
        XCTAssertTrue(error.contains("create"), "Should show create command in error output")
    }
    
    func testMachineCommandHelp() throws {
        let (output, error) = try run(commands: ["machine", "-h"], exitCode: 0)
        XCTAssertEqual(error, "")
        XCTAssertTrue(output.contains("OVERVIEW"), "Should show command overview in output")
        XCTAssertTrue(output.contains("create"), "Should show create command in output")
    }
    
    func testMachineCreateCommand() throws {
        let (output, error) = try run(commands: ["machine", "create", "--unit-test", "robtest1", "robtest2", "robtest3"], exitCode: 0)
        (1...3).forEach { (i) in
            XCTAssertTrue(
                output.contains("docker-machine create robtest\(i)\nCreated machine robtest\(i)")
            )
        }
        
        XCTAssertTrue(
            output.contains("Machines created successfully!\n")
        )
        
        XCTAssertEqual(error, "")
    }
    
    func testMachineCreateCommandWithArgs() throws {
        let (output, error) = try run(commands: ["machine", "create", "--unit-test", "--amazonec2-access-key", "foobar", "--amazonec2-secret-key", "secret", "robtest1", "robtest2", "robtest3"], exitCode: 0)
        (1...3).forEach { (i) in
            XCTAssertTrue(
                output.contains("docker-machine create --amazonec2-access-key foobar --amazonec2-secret-key secret robtest\(i)\nCreated machine robtest\(i)")
            )
        }
        XCTAssertTrue(
            output.contains(
                "Machines created successfully!\n"
            )
        )
        XCTAssertEqual(error, "")
    }
    
    func testMachineCreateCommandWithArgsQuiet() throws {
        let (output, error) = try run(commands: ["machine", "create", "-q", "--unit-test", "--amazonec2-access-key", "foobar", "--amazonec2-secret-key", "secret", "robtest1", "robtest2", "robtest3"], exitCode: 0)
        (1...3).forEach { (i) in
            XCTAssertTrue(
                output.contains("robtest\(i)")
            )
        }
        XCTAssertEqual(error, "")
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
      ("testMachineCommand", testMachineCommand),
    ]
}
