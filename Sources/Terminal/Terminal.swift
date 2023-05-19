import Foundation

public struct Terminal {
    
    private let lockQueue: DispatchQueue
    public var type: String
    public var env: [String: String]
    
    #if os(macOS)
    public var outputHandler: TerminalDataHandler?
    public var errorHandler: TerminalDataHandler?
    #endif
    
    
    public init(type: ShellType = .bash, env: [String: String] = [:]) {
        self.lockQueue = DispatchQueue(label: "terminal.lock.queue")
        self.type = type.rawValue
        self.env = env
    }
    
    @discardableResult
    public func execute(_ command: String) throws -> String {
        
        let process = Process()
        process.launchPath = self.type
        process.arguments = ["-c", command]
        
        if !self.env.isEmpty {
            process.environment = ProcessInfo.processInfo.environment
            self.env.forEach { variable in
                process.environment?[variable.key] = variable.value
            }
        }
        
        var outputData = Data()
        let outputPipe = Pipe()
        
        process.standardOutput = outputPipe
        
        var errorData = Data()
        let errorPipe = Pipe()
        process.standardError = errorPipe
        
        #if os(macOS)
        outputPipe.fileHandleForReading.readabilityHandler = { handler in
            let data = handler.availableData
            self.lockQueue.async {
                outputData.append(data)
                self.outputHandler?.handle(data)
            }
        }
        errorPipe.fileHandleForReading.readabilityHandler = { handler in
            let data = handler.availableData
            self.lockQueue.async {
                errorData.append(data)
                self.errorHandler?.handle(data)
            }
        }
        #endif
        
        process.launch()
        
        #if os(Linux)
        self.lockQueue.sync {
            outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        }
        #endif
        
        process.waitUntilExit()
        
        #if os(macOS)
        self.outputHandler?.end()
        self.errorHandler?.end()
        
        outputPipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil
        
        #endif
        
        return try self.lockQueue.sync {
            guard process.terminationStatus == 0 else {
                var message = "Unknown error"
                if let error = String(data: errorData, encoding: .utf8) {
                    message = error.trimmingCharacters(in: .newlines)
                }
                throw Error.generic(Int(process.terminationStatus), message)
            }
            guard let output = String(data: outputData, encoding: .utf8) else {
                throw Error.outputData
            }
            return output.trimmingCharacters(in: .newlines)
        }
    }
    
    public func execute(_ command: String, completion: @escaping ((String?, Swift.Error?) -> Void)) {
        let queue = DispatchQueue(label: "terminal.process.queue", attributes: .concurrent)
        queue.async {
            do {
                let output = try self.execute(command)
                completion(output, nil)
            }
            catch {
                completion(nil, error)
            }
        }
    }
}
