import Foundation
import SwiftUI
import Combine

final class PhantomNetworkViewModel: ObservableObject {

    enum FilterType: String, CaseIterable, Identifiable {
        case all = "All"
        case errors = "Errors"
        case slow = "Slow >1s"
        var id: String { rawValue }
    }

    @Published var searchText: String = ""
    @Published var selectedFilter: FilterType = .all

    private let networkLogger = PhantomNetworkLogger.shared
    private var cancellables = Set<AnyCancellable>()

    var totalCount: Int {
        networkLogger.logs.count
    }

    var filteredLogs: [PhantomNetworkItem] {
        var list = Array(networkLogger.logs.reversed())
        switch selectedFilter {
        case .all:
            break
        case .errors:
            list = list.filter { ($0.statusCode ?? 0) >= 400 }
        case .slow:
            list = list.filter { ($0.durationMs ?? 0) > 1000 }
        }
        guard !searchText.isEmpty else { return list }
        let query = searchText.lowercased()
        return list.filter { item in
            let url = item.url?.absoluteString.lowercased() ?? ""
            let request = item.requestBody.lowercased()
            let response = item.responseBody.lowercased()
            let headers = "\(item.requestHeaders)\n\(item.responseHeaders)".lowercased()
            return url.contains(query) || request.contains(query) || response.contains(query) || headers.contains(query)
        }
    }

    init() {
        networkLogger.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func clearAll() {
        networkLogger.clearAll()
    }

    func isMockLog(_ item: PhantomNetworkItem) -> Bool {
        item.responseHeaders == "[MOCK]"
    }

    func pathText(for item: PhantomNetworkItem) -> String {
        guard let url = item.url else { return "No URL" }
        return url.path.isEmpty ? (url.host ?? url.absoluteString) : url.path
    }

    func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    func formattedBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    func statusColor(_ item: PhantomNetworkItem, theme: PhantomTheme) -> Color {
        guard let status = item.statusCode else {
            return item.completedAt == nil ? theme.error : theme.onBackgroundVariant
        }
        return (200..<300).contains(status) ? theme.success : theme.error
    }

    func statusBackgroundColor(for status: Int, theme: PhantomTheme) -> Color {
        if (200..<300).contains(status) { return theme.success.opacity(0.18) }
        if (300..<500).contains(status) { return theme.warning.opacity(0.18) }
        return theme.error.opacity(0.16)
    }

    func statusTextColor(for status: Int, theme: PhantomTheme) -> Color {
        if (200..<300).contains(status) { return theme.success }
        if (300..<500).contains(status) { return theme.warning }
        return theme.error
    }
}
