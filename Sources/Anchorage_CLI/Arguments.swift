//
//  File.swift
//  Anchorage-CLI
//
//  Created by Robert Harrison on 15/10/2018.
//

//import Foundation

func prepare(arguments: [String]) -> [String] {
    return Array(arguments.dropFirst())
}
