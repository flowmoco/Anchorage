//
//  Errors.swift
//  Anchorage
//
//  Created by Robert Harrison on 24/10/2018.
//

import Foundation

public func print(errorMessage: String) {
    guard let data = ( errorMessage + "\n" ).data(using: .utf8) else {
        return
    }
    FileHandle.standardError.write(data)
}
