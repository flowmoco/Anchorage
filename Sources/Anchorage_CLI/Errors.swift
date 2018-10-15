//
//  Errors.swift
//  Anchorage_CLI
//
//  Created by Robert Harrison on 15/10/2018.
//

import Foundation

import Foundation
import Utility

func print(errorMessage: String) {
    guard let data = ( errorMessage + "\n" ).data(using: .utf8) else {
        return
    }
    FileHandle.standardError.write(data)
}

public func handle(error: Error) {
    print(errorMessage: error.localizedDescription)
    exit(1)
}

public func handle(error: ArgumentParserError) {
    print(errorMessage: error.description + "\n")
    handle(error: error as Error)
}
