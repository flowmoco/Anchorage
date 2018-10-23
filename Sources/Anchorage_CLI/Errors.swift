//
//  Errors.swift
//  Anchorage_CLI
//
//  Created by Robert Harrison on 15/10/2018.
//

import Foundation

import Foundation
import Utility

enum CLIError: Error {
    case createMachineFailed(status: Int32)
    
    var localizedDescription: String {
        switch self {
        case .createMachineFailed(let status):
            let message = NSLocalizedString("Some docker-machine commands exited with a non-zero exit status: %@", comment: "CLIErrorMessage createMachineFailed")
            return String(format: message, String(status))
        }
    }
}

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

