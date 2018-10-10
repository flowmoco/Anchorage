import XCTest
import class Foundation.Bundle
@testable import Anchorage

final class anchorageTests: XCTestCase {
    
    func testDefaultConfigURL() throws {
        let fileManager = FileManager.default
        let file = try defaultConfigFile(with: fileManager)
        XCTAssertEqual("/Users/robwithhair/.anchorage/defaultConfig.json", file.path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: try anchorageDirectory(with: fileManager).path), "Anchorage directory doesn't exist")
        let config = try defaultConfig(with: fileManager)
        XCTAssertEqual(config.driver.name, "amazonec2")
    }
    
    func testMachineNames() throws {
        XCTAssertEqual( try valid(identifier: "flowmoco-cluster-123"), "flowmoco-cluster-123")
        XCTAssertEqual( try valid(identifier: "Flowmoco-Cluster-123"), "Flowmoco-Cluster-123")
        XCTAssertThrowsError( try valid(identifier: "test_not_work"))
    }
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }

        let fooBinary = productsDirectory.appendingPathComponent("anchor")

        let process = Process()
        process.executableURL = fooBinary

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)

        XCTAssertEqual(output, "Hello world\n")
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
        ("testExample", testExample),
    ]
}
