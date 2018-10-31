//
//  FileFunctions.swift
//  Anchorage
//
//  Created by Robert Harrison on 31/10/2018.
//

import Foundation

func writeAndClose(string: String?, toFileHandle fileHandle: FileHandle) {
    if let data = string?.data(using: .utf8) {
        fileHandle.write(data)
    }
    fileHandle.closeFile()
}
