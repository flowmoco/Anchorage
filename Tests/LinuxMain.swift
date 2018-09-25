import XCTest

import anchorageTests

var tests = [XCTestCaseEntry]()
tests += anchorageTests.allTests()
XCTMain(tests)