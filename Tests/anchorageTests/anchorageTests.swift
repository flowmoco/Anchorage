import XCTest
import class Foundation.Bundle
@testable import Anchorage

final class anchorageTests: XCTestCase {
    
    func testCreatingCluster() throws {
        let fm = FileManager.default
        let cluster = try Cluster(name: "test-cluster")
        try cluster.save(using: fm)
        _ = try Cluster.with(name: cluster.name, using: fm)
        let list = try Cluster.list(using: fm)
        XCTAssertTrue(list.contains("test-cluster"))
        try cluster.delete(using: fm)
    }
    
    func testRunningProcessAsync() throws {
        let path = FileManager.default.currentDirectoryPath
        let opKeys = ["ls1", "ls2", "ls3"]
        let q = ProcessOperation.defaultQueue
        let ops: [ProcessOperation] = opKeys.reduce(into: [ProcessOperation]()) { (res, key) in
            let ls = ProcessOperation(commands: ["ls"], currentDirectory: URL(fileURLWithPath: path))
            res.append(ls)
            q.addOperation(ls)
        }
        
        q.waitUntilAllOperationsAreFinished()
        ops.forEach { (op) in
            XCTAssertEqual(op.terminationStatus, 0)
            XCTAssertTrue(op.standardOutput?.contains("Anchor") ?? false)
        }
    }
    
    func testRunningProcess() throws {
        let path = FileManager.default.currentDirectoryPath
        let ls = ProcessOperation(commands: ["ls"], currentDirectory: URL(fileURLWithPath: path)).startAndWait()
        XCTAssertEqual(ls.terminationStatus, 0)
        let p1 = ProcessOperation(commands: ["dockerfds"], currentDirectory: URL(fileURLWithPath: path)).startAndWait()
        XCTAssertEqual(p1.terminationStatus, 127)
        XCTAssertEqual(p1.standardOutput ?? "fail", "")
        XCTAssertEqual(p1.standardError ?? "", "env: dockerfds: No such file or directory\n")
        do {
            let docker = ProcessOperation(commands: ["ls", "-D"], currentDirectory: URL(fileURLWithPath: path)).startAndWait()
            let out = try docker.output()
            XCTAssertEqual(docker.terminationStatus, 1)
            XCTAssertEqual(docker.terminationReason, .exit)
            XCTAssertTrue(out.contains("illegal option"))
        } catch {
            XCTFail("Threw unexpected error: \(error)")
        }
    }
    
    func testDefaultConfigURL() throws {
        let fileManager = FileManager.default
        let file = try defaultConfigFile(with: fileManager)
        XCTAssertEqual("/Users/robwithhair/.anchorage/defaultMachineConfig.json", file.path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: try anchorageDirectory(with: fileManager).path), "Anchorage directory doesn't exist")
        let config = try defaultConfig(with: fileManager)
        XCTAssertEqual(config.driverName, "amazonec2")
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
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        
        XCTAssertTrue( output!.contains("command is used to manage a docker swarm cluster"))
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
        ("testCreatingCluster", testCreatingCluster),
        ("testRunningProcessAsync", testRunningProcessAsync),
        ("testRunningProcess", testRunningProcess),
        ("testDefaultConfigURL", testDefaultConfigURL),
        ("testMachineNames", testMachineNames),
        ("testExample", testExample),
    ]
}
