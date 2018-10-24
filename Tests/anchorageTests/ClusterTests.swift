//
//  ClusterTests.swift
//  AnchorageTests
//
//  Created by Robert Harrison on 24/10/2018.
//

import XCTest
import class Foundation.Bundle
@testable import Anchorage

final class ClusterTests: XCTestCase {

    func testCreateNames() throws {
        let name = "test-me"
        var number = 3
        var cluster = try Cluster(name: "test-me", initialSwarmManagers: number, initialSwarmWorkers: number, initialCephNodes: number)
        Cluster.Kinds.allCases.forEach { (kind) in
            let expected = [
                "\(name)-\(kind.rawValue)-1",
                "\(name)-\(kind.rawValue)-2",
                "\(name)-\(kind.rawValue)-3",
            ]
            XCTAssertEqual(cluster.initialNames(for: kind), expected)
            XCTAssertEqual(cluster.newNames(quantity: number, forNodeKind: kind), expected)
            cluster.nodes[kind] = cluster.initialNames(for: kind)
            cluster.nodes[kind]!.removeFirst()
        }
        
        number = 2
        
        Cluster.Kinds.allCases.forEach { (kind) in
            let expected = [
                "\(name)-\(kind.rawValue)-4",
                "\(name)-\(kind.rawValue)-5",
            ]
            XCTAssertEqual(cluster.newNames(quantity: number, forNodeKind: kind), expected)
            cluster.nodes[kind]!.remove(at: 1)
        }
        
        Cluster.Kinds.allCases.forEach { (kind) in
            let expected = [
                "\(name)-\(kind.rawValue)-3",
                "\(name)-\(kind.rawValue)-4",
            ]
            XCTAssertEqual(cluster.newNames(quantity: number, forNodeKind: kind), expected)
        }
        
    }
    
    func testInvalidClusterConfig() throws {
        XCTAssertThrowsError(
            try Cluster(name: "test_me", initialSwarmManagers: nil, initialSwarmWorkers: nil, initialCephNodes: nil)
        )
        XCTAssertThrowsError(
            try Cluster(name: "test-cluster", initialSwarmManagers: nil, initialSwarmWorkers: 1, initialCephNodes: nil)
        )
        XCTAssertThrowsError(
            try Cluster(name: "test-cluster", initialSwarmManagers: 0, initialSwarmWorkers: 1, initialCephNodes: nil)
        )
    }

//    func testExample() {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
    static var allTests = [
        ("testCreateNames", testCreateNames),
        ("testInvalidClusterConfig", testInvalidClusterConfig),
    ]
}
