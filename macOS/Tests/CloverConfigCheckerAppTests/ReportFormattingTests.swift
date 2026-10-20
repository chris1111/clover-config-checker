import XCTest
@testable import CloverConfigCheckerApp

final class ReportFormattingTests: XCTestCase {
    func testIssueAndResultColors() {
        XCTAssertEqual(ReportFormatting.tone(for: "ERROR: unknown key"), .error)
        XCTAssertEqual(ReportFormatting.tone(for: "Error: cannot read file"), .error)
        XCTAssertEqual(ReportFormatting.tone(for: "WARNING: deprecated key"), .warning)
        XCTAssertEqual(ReportFormatting.tone(for: "NOTE: documentation key"), .note)
        XCTAssertEqual(ReportFormatting.tone(for: "Result: INVALID -- 1 error(s) found"), .error)
        XCTAssertEqual(ReportFormatting.tone(for: "Result: VALID with warnings"), .warning)
        XCTAssertEqual(ReportFormatting.tone(for: "Result: VALID"), .success)
    }

    func testSectionColors() {
        XCTAssertEqual(ReportFormatting.tone(for: "  Boot: 15 keys verified"), .success)
        XCTAssertEqual(ReportFormatting.tone(for: "  ACPI: 160 keys -- 1 error"), .error)
        XCTAssertEqual(ReportFormatting.tone(for: "  GUI: 79 keys -- 1 warning"), .warning)
        XCTAssertEqual(ReportFormatting.tone(for: "  Boot: 15 keys -- 2 notes"), .note)
        XCTAssertEqual(ReportFormatting.tone(for: "  Total: 474 keys in 12 sections"), .secondary)
        XCTAssertEqual(ReportFormatting.tone(for: "  error: 3 keys verified"), .success)
    }

    func testFormattingPreservesFullTextAndAppliesColors() {
        let output = "ERROR: wrong type\n  Boot: 15 keys verified\nResult: INVALID\n"
        let formatted = ReportFormatting.attributed(output)
        XCTAssertEqual(String(formatted.characters), output)
        XCTAssertEqual(formatted.runs.count, 3)
        XCTAssertTrue(formatted.runs.allSatisfy { $0.foregroundColor != nil })
    }
}
