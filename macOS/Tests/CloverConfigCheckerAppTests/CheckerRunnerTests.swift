import Foundation
import XCTest
@testable import CloverConfigCheckerApp

final class CheckerRunnerTests: XCTestCase {
    private var root: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    func testValidConfiguration() throws {
        let report = try CheckerRunner(backendURL: root)
            .check(root.appendingPathComponent("samples/config-valid.plist"))
        XCTAssertEqual(report.exitCode, 0)
        XCTAssertTrue(report.output.contains("Result: VALID"))
        XCTAssertFalse(report.output.contains("\u{001B}["))
    }

    func testInvalidConfiguration() throws {
        let report = try CheckerRunner(backendURL: root)
            .check(root.appendingPathComponent("samples/config-bad-typo.plist"))
        XCTAssertEqual(report.exitCode, 1)
        XCTAssertTrue(report.output.contains("Result: INVALID"))
        XCTAssertTrue(report.output.contains("ERROR:"))
    }

    func testMissingFile() throws {
        let report = try CheckerRunner(backendURL: root)
            .check(root.appendingPathComponent("samples/does-not-exist.plist"))
        XCTAssertEqual(report.exitCode, 2)
        XCTAssertTrue(report.output.contains("cannot read"))
    }

    func testFileWithSpacesAndUnicodeIsNotModified() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("config com espaço.plist")
        let original = try Data(contentsOf: root.appendingPathComponent("samples/config-valid.plist"))
        try original.write(to: url)
        let report = try CheckerRunner(backendURL: root).check(url)
        XCTAssertEqual(report.exitCode, 0)
        XCTAssertEqual(try Data(contentsOf: url), original)
    }
}
