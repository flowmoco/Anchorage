//
//  Arguments.swift
//  Anchor
//
//  Created by Robert Harrison on 25/09/2018.
//

import Foundation

func argumentList() -> [String] {
    return Array(ProcessInfo.processInfo.arguments.dropFirst())
}
