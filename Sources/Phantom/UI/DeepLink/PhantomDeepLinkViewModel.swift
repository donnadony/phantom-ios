import Foundation
import UIKit

final class PhantomDeepLinkViewModel: ObservableObject {

    struct HistoryItem: Identifiable {
        let id = UUID()
        let url: String
        let timestamp: Date
        let success: Bool
    }

    @Published var urlText: String = ""
    @Published var history: [HistoryItem] = []
    @Published var errorMessage: String?

    private let historyKey = "phantom_deeplink_history"

    init() {
        loadHistory()
    }

    func openLink() {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Enter a URL or scheme"
            return
        }
        guard let url = URL(string: trimmed) else {
            errorMessage = "Invalid URL format"
            addHistory(trimmed, success: false)
            return
        }
        errorMessage = nil
        UIApplication.shared.open(url, options: [:]) { [weak self] success in
            DispatchQueue.main.async {
                self?.addHistory(trimmed, success: success)
                if !success {
                    self?.errorMessage = "No app handled this URL"
                }
            }
        }
    }

    func clearHistory() {
        history.removeAll()
        UserDefaults.standard.removeObject(forKey: historyKey)
    }

    func selectHistoryItem(_ item: HistoryItem) {
        urlText = item.url
    }

    func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    private func addHistory(_ url: String, success: Bool) {
        let item = HistoryItem(url: url, timestamp: Date(), success: success)
        history.insert(item, at: 0)
        if history.count > 50 { history = Array(history.prefix(50)) }
        saveHistory()
    }

    private func saveHistory() {
        let data: [[String: Any]] = history.map {
            ["url": $0.url, "timestamp": $0.timestamp.timeIntervalSince1970, "success": $0.success]
        }
        UserDefaults.standard.set(data, forKey: historyKey)
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.array(forKey: historyKey) as? [[String: Any]] else { return }
        history = data.compactMap { dict in
            guard let url = dict["url"] as? String,
                  let ts = dict["timestamp"] as? TimeInterval,
                  let success = dict["success"] as? Bool else { return nil }
            return HistoryItem(url: url, timestamp: Date(timeIntervalSince1970: ts), success: success)
        }
    }
}
