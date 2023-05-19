//
//  TerminalDataHandler.swift
//  
//
//  Created by Asiel Cabrera Gonzalez on 5/18/23.
//

import Foundation

#if os(macOS)

public protocol TerminalDataHandler {

    func handle(_ data: Data)

    func end()
}

public extension TerminalDataHandler {

    func end() { }
}

#endif
