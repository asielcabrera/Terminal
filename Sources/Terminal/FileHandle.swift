//
//  FileHandle.swift
//  
//
//  Created by Asiel Cabrera Gonzalez on 5/18/23.
//

import Foundation

#if os(macOS)
private extension FileHandle {
    var isStandard: Bool {
        return self === FileHandle.standardOutput || self === FileHandle.standardError || self === FileHandle.standardInput
    }
}

extension FileHandle: TerminalDataHandler {

    public func handle(_ data: Data) {
        self.write(data)
    }

    public func end() {
        guard !self.isStandard else {
            return
        }
        self.closeFile()
    }
}
#endif
