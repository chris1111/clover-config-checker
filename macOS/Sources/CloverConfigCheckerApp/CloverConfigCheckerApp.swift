import AppKit
import SwiftUI
import UniformTypeIdentifiers

@main
struct CloverConfigCheckerApp: App {
    var body: some Scene {
        WindowGroup("Clover Config Checker") {
            CheckerView()
        }
        .defaultSize(width: 780, height: 580)
        .defaultPosition(.center)
        .windowResizability(.contentMinSize)
    }
}

struct CheckerView: View {
    @State private var isTargeted = false
    @State private var isChecking = false
    @State private var fileURL: URL?
    @State private var report: CheckReport?
    @State private var errorMessage: String?

    private var statusColor: Color {
        guard let report else { return CloverTheme.text }
        return report.exitCode == 0 ? CloverTheme.accent : (report.exitCode == 1 ? CloverTheme.warning : .red)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Clover Config Checker")
                        .font(.title2.bold())
                    Text("Verifique seu config.plist sem alterar o arquivo.")
                        .foregroundStyle(CloverTheme.secondary)
                }
                Spacer()
            }

            VStack(spacing: 6) {
                Image(systemName: "doc.badge.arrow.up")
                    .font(.system(size: 24))
                Text(isChecking ? "Verificando configuração..." : "Arraste seu config.plist aqui")
                    .font(.headline)
                Button("Escolher arquivo...") {
                    chooseFile()
                }
                .disabled(isChecking)
                if isChecking {
                    ProgressView().controlSize(.small)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(isTargeted ? CloverTheme.accent.opacity(0.16) : CloverTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isTargeted ? CloverTheme.accent : CloverTheme.accent.opacity(0.4),
                                  style: StrokeStyle(lineWidth: 2, dash: [7]))
            )
            .dropDestination(for: URL.self) { urls, _ in
                guard !isChecking else { return false }
                guard urls.count == 1, let url = urls.first, url.isFileURL else {
                    errorMessage = "Arraste apenas um arquivo .plist por vez."
                    return false
                }
                check(url)
                return true
            } isTargeted: { targeted in
                isTargeted = targeted
            }

            if let fileURL {
                Text(fileURL.path)
                    .font(.caption)
                    .foregroundStyle(CloverTheme.secondary)
                    .textSelection(.enabled)
            }
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }

            HStack {
                Text(report?.title ?? "Relatório")
                    .font(.headline)
                    .foregroundStyle(statusColor)
                Spacer()
                Button("Copiar relatório") {
                    guard let report else { return }
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(report.output, forType: .string)
                }
                .disabled(report == nil || isChecking)
            }
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    Text(ReportFormatting.attributed(
                        report?.output ?? "O resultado da verificação aparecerá aqui."
                    ))
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(12)
                        .id("reportTop")
                }
                .onChange(of: report?.output) { _ in
                    proxy.scrollTo("reportTop", anchor: .top)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 160, maxHeight: .infinity)
            .layoutPriority(1)
            .background(CloverTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(CloverTheme.accent.opacity(0.2))
            )

            Text("VALID não garante compatibilidade com seu hardware. Revise os avisos antes de usar a configuração.")
                .font(.caption)
                .foregroundStyle(CloverTheme.secondary)
        }
        .padding(18)
        .frame(minWidth: 560, minHeight: 480)
        .foregroundStyle(CloverTheme.text)
        .tint(CloverTheme.accent)
        .background(CloverTheme.background.ignoresSafeArea())
    }

    private func chooseFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.propertyList]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Selecione a configuração Clover que deseja verificar."
        if panel.runModal() == .OK, let url = panel.url {
            check(url)
        }
    }

    private func check(_ url: URL) {
        guard !isChecking else { return }
        errorMessage = nil
        report = nil
        fileURL = url
        guard url.pathExtension.lowercased() == "plist",
              !url.hasDirectoryPath else {
            errorMessage = "Selecione um arquivo com extensão .plist."
            return
        }
        isChecking = true
        Task { @MainActor in
            defer { isChecking = false }
            do {
                let runner = try CheckerRunner.bundled()
                report = try await Task.detached(priority: .userInitiated) {
                    try runner.check(url)
                }.value
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
