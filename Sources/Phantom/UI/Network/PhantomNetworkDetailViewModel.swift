import Foundation
import SwiftUI

final class PhantomNetworkDetailViewModel: ObservableObject {

    enum DetailTab: String, CaseIterable, Identifiable {
        case request = "Request"
        case response = "Response"
        case headers = "Headers"
        var id: String { rawValue }
    }

    let item: PhantomNetworkItem

    @Published var selectedTab: DetailTab = .response
    @Published var showJsonTree: Bool = true
    @Published var copiedMessage: String?
    @Published var mockRuleToCreate: PhantomMockRule?
    @Published var mockRuleToEdit: PhantomMockRule?

    var isMock: Bool {
        item.responseHeaders == "[MOCK]"
    }

    var statusText: String {
        if let status = item.statusCode { return "\(status)" }
        return ""
    }

    var formattedBytes: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(item.responseSizeBytes))
    }

    var plainText: String {
        switch selectedTab {
        case .request:
            return item.requestBody.isEmpty ? "No body" : item.requestBody
        case .response:
            return item.responseBody.isEmpty ? "No response body" : item.responseBody
        case .headers:
            return "Request Headers:\n\(item.requestHeaders)\n\nResponse Headers:\n\(item.responseHeaders)"
        }
    }

    init(item: PhantomNetworkItem) {
        self.item = item
    }

    func headersAsJson(_ headerString: String) -> String {
        if headerString.hasPrefix("{") || headerString.hasPrefix("[") {
            return headerString
        }
        var dict: [String: String] = [:]
        let lines = headerString.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            if let colonIndex = trimmed.firstIndex(of: ":") {
                let key = String(trimmed[trimmed.startIndex..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let value = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                if !key.isEmpty {
                    dict[key] = value
                }
            }
        }
        guard !dict.isEmpty,
              let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
              let json = String(data: data, encoding: .utf8) else {
            return headerString
        }
        return json
    }

    func copyCurrentTab() {
        let text: String
        switch selectedTab {
        case .request:
            text = item.requestBody.isEmpty ? "No body" : item.requestBody
        case .response:
            text = item.responseBody.isEmpty ? "No response body" : item.responseBody
        case .headers:
            text = "Request Headers:\n\(item.requestHeaders)\n\nResponse Headers:\n\(item.responseHeaders)"
        }
        UIPasteboard.general.string = text
        showCopiedFeedback("Copied")
    }

    func copyURL() {
        UIPasteboard.general.string = item.url?.absoluteString ?? ""
        showCopiedFeedback("URL copied")
    }

    func createMock() {
        mockRuleToCreate = buildMockRule()
    }

    func editMock() {
        mockRuleToEdit = findMockRule()
    }

    func handleMockCreated(_ rule: PhantomMockRule) {
        PhantomMockInterceptor.shared.addRule(rule)
        mockRuleToCreate = nil
    }

    func handleMockUpdated(_ rule: PhantomMockRule) {
        PhantomMockInterceptor.shared.updateRule(rule)
        mockRuleToEdit = nil
    }

    func statusTextColor(theme: PhantomTheme) -> Color {
        guard let status = item.statusCode else { return theme.onBackgroundVariant }
        if (200..<300).contains(status) { return theme.success }
        if (300..<500).contains(status) { return theme.warning }
        return theme.error
    }

    func statusBackgroundColor(theme: PhantomTheme) -> Color {
        guard let status = item.statusCode else { return theme.surface }
        if (200..<300).contains(status) { return theme.success.opacity(0.18) }
        if (300..<500).contains(status) { return theme.warning.opacity(0.18) }
        return theme.error.opacity(0.16)
    }

    private func buildMockRule() -> PhantomMockRule {
        let path = item.url?.path ?? ""
        let responseId = UUID()
        let response = PhantomMockResponse(
            id: responseId,
            name: "Response 1",
            statusCode: item.statusCode ?? 200,
            responseBody: item.responseBody
        )
        return PhantomMockRule(
            id: UUID(),
            isEnabled: true,
            urlPattern: path,
            httpMethod: item.methodType,
            responses: [response],
            activeResponseId: responseId,
            ruleDescription: "Mock \(path.split(separator: "/").last ?? "endpoint")",
            createdAt: Date()
        )
    }

    private func findMockRule() -> PhantomMockRule? {
        guard let path = item.url?.path else { return nil }
        return PhantomMockInterceptor.shared.rules.first { rule in
            guard rule.httpMethod == "ANY" || rule.httpMethod == item.methodType else { return false }
            return path.contains(rule.urlPattern)
        }
    }

    func buildCurlCommand() -> String {
        let method = item.methodType
        let url = item.url?.absoluteString ?? ""
        let escapedUrl = url.replacingOccurrences(of: "'", with: "'\\''")
        var parts = ["curl -X \(method) '\(escapedUrl)'"]
        let headerString = item.requestHeaders
        if !headerString.isEmpty && headerString != "No headers" {
            if headerString.hasPrefix("{") || headerString.hasPrefix("[") {
                if let data = headerString.data(using: .utf8),
                   let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    for (key, value) in dict.sorted(by: { $0.key < $1.key }) {
                        parts.append("-H '\(key): \(value)'")
                    }
                }
            } else {
                let lines = headerString.components(separatedBy: "\n")
                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty, let colonIndex = trimmed.firstIndex(of: ":") else { continue }
                    let key = String(trimmed[trimmed.startIndex..<colonIndex]).trimmingCharacters(in: .whitespaces)
                    let value = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                    guard !key.isEmpty else { continue }
                    parts.append("-H '\(key): \(value)'")
                }
            }
        }
        if !item.requestBody.isEmpty {
            let escapedBody = item.requestBody.replacingOccurrences(of: "'", with: "'\\''")
            parts.append("-d '\(escapedBody)'")
        }
        return parts.joined(separator: " \\\n  ")
    }

    func copyCurl() {
        UIPasteboard.general.string = buildCurlCommand()
        showCopiedFeedback("cURL copied")
    }

    private func showCopiedFeedback(_ message: String) {
        copiedMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.copiedMessage = nil
        }
    }
}
