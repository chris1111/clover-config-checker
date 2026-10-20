import Foundation

struct CheckReport: Sendable {
    let output: String
    let exitCode: Int32

    var title: String {
        switch exitCode {
        case 0: return "Configuração válida"
        case 1: return "Configuração com problemas"
        default: return "Não foi possível verificar"
        }
    }
}

enum CheckerError: LocalizedError {
    case missingBackend
    case missingPython
    case unexpectedExit(Int32, String)

    var errorDescription: String? {
        switch self {
        case .missingBackend:
            return "O verificador não foi encontrado no aplicativo. Gere o app novamente com build_app.sh."
        case .missingPython:
            return "Python 3 não encontrado. Instale Python 3.8 ou superior e tente novamente."
        case let .unexpectedExit(code, output):
            return "O verificador encerrou inesperadamente (código \(code)).\n\(output)"
        }
    }
}

struct CheckerRunner: Sendable {
    let backendURL: URL

    static func bundled() throws -> CheckerRunner {
        guard let resources = Bundle.main.resourceURL else {
            throw CheckerError.missingBackend
        }
        let backend = resources.appendingPathComponent("Backend", isDirectory: true)
        guard FileManager.default.fileExists(
            atPath: backend.appendingPathComponent("clover_config_checker/__main__.py").path
        ) else {
            throw CheckerError.missingBackend
        }
        return CheckerRunner(backendURL: backend)
    }

    func check(_ fileURL: URL) throws -> CheckReport {
        let environment = ProcessInfo.processInfo.environment
        let searchPaths = (environment["PATH"] ?? "").split(separator: ":").map(String.init)
            + ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin"]
        guard let python = searchPaths
            .map({ URL(fileURLWithPath: $0).appendingPathComponent("python3") })
            .first(where: { FileManager.default.isExecutableFile(atPath: $0.path) }) else {
            throw CheckerError.missingPython
        }

        let process = Process()
        process.executableURL = python
        process.arguments = [
            "-B", "-m", "clover_config_checker", "--color", "never", "--", fileURL.path
        ]
        process.currentDirectoryURL = backendURL
        var childEnvironment = environment
        childEnvironment["PYTHONPATH"] = backendURL.path
        childEnvironment["PYTHONIOENCODING"] = "utf-8"
        childEnvironment["PYTHONNOUSERSITE"] = "1"
        process.environment = childEnvironment

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        // Drain the pipe before waiting so a large report cannot block the child.
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let output = String(decoding: data, as: UTF8.self)
        guard process.terminationReason == .exit,
              [0, 1, 2].contains(process.terminationStatus),
              !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CheckerError.unexpectedExit(process.terminationStatus, output)
        }
        return CheckReport(output: output, exitCode: process.terminationStatus)
    }
}
