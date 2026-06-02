import Foundation
import SwiftUI
import Combine

final class PhantomLogsViewModel: ObservableObject {
    
    // MARK: - Properties

    @Published var searchText: String = ""
    @Published var selectedLevel: PhantomLogLevel?

    private let logger = PhantomLogger.shared
    private var cancellables = Set<AnyCancellable>()

    var totalCount: Int {
        logger.events.count
    }

    var filteredEvents: [PhantomLogItem] {
        var list = logger.events
        if let level = selectedLevel {
            list = list.filter { $0.level == level }
        }
        guard !searchText.isEmpty else { return list }
        let query = searchText.lowercased()
        return list.filter { item in
            item.message.lowercased().contains(query) ||
            (item.tag ?? "").lowercased().contains(query)
        }
    }
    
    // MARK: - Lifecycle

    init() {
        logger.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func clearAll() {
        logger.clearAll()
    }

    func selectLevel(_ level: PhantomLogLevel?) {
        selectedLevel = level
    }

    func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    func levelColor(_ level: PhantomLogLevel, theme: PhantomTheme) -> Color {
        switch level {
        case .info: return theme.info
        case .warning: return theme.warning
        case .error: return theme.error
        }
    }

    func exportData() -> Data? {
        let events = logger.events
        guard !events.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        let entries: [[String: Any]] = events.map { item in
            var dict: [String: Any] = [
                "level": item.level.rawValue,
                "message": item.message,
                "timestamp": formatter.string(from: item.createdAt)
            ]
            if let tag = item.tag { dict["tag"] = tag }
            return dict
        }
        let payload: [String: Any] = [
            "exported_at": formatter.string(from: Date()),
            "type": "phantom_logs",
            "count": entries.count,
            "entries": entries
        ]
        return try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
    }
}
