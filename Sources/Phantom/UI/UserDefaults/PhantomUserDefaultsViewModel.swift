import Foundation
import SwiftUI

final class PhantomUserDefaultsViewModel: ObservableObject {

    enum GroupFilter: String, CaseIterable {
        case all = "All"
        case phantom = "Phantom"
        case app = "App"
    }

    struct UserDefaultsEntry: Identifiable {
        let id = UUID()
        let key: String
        let value: Any
        let typeLabel: String
        let displayValue: String
        var boolValue: Bool?
    }

    @Published var entries: [UserDefaultsEntry] = []
    @Published var searchText: String = ""
    @Published var selectedGroup: GroupFilter = .all
    @Published var showAddSheet = false
    @Published var editingEntry: UserDefaultsEntry?

    var filteredEntries: [UserDefaultsEntry] {
        entries.filter { entry in
            let matchesSearch = searchText.isEmpty || entry.key.localizedCaseInsensitiveContains(searchText)
            let matchesGroup: Bool
            switch selectedGroup {
            case .all:
                matchesGroup = true
            case .phantom:
                matchesGroup = entry.key.hasPrefix("phantom_")
            case .app:
                matchesGroup = !entry.key.hasPrefix("phantom_")
            }
            return matchesSearch && matchesGroup
        }
    }

    init() {
        loadEntries()
    }

    func loadEntries() {
        let all = UserDefaults.standard.dictionaryRepresentation()
        let registrationKeys = Self.registrationDomainKeys()
        entries = all.keys.sorted().compactMap { key in
            guard !registrationKeys.contains(key) else { return nil }
            let value = all[key]!
            let (typeLabel, displayValue, boolValue) = resolveType(value)
            return UserDefaultsEntry(
                key: key,
                value: value,
                typeLabel: typeLabel,
                displayValue: displayValue,
                boolValue: boolValue
            )
        }
    }

    private static func registrationDomainKeys() -> Set<String> {
        var keys = Set<String>()
        for name in UserDefaults.standard.volatileDomainNames {
            let domain = UserDefaults.standard.volatileDomain(forName: name)
            keys.formUnion(domain.keys)
        }
        let systemPrefixes = [
            "AK", "Apple", "NS", "ABS", "AddingEmoji", "CarPlay",
            "MultiplayerGameController", "PK", "MSV", "com.apple.",
        ]
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in allKeys {
            if systemPrefixes.contains(where: { key.hasPrefix($0) }) {
                keys.insert(key)
            }
        }
        return keys
    }

    func toggleBool(for entry: UserDefaultsEntry) {
        guard let current = entry.boolValue else { return }
        UserDefaults.standard.set(!current, forKey: entry.key)
        loadEntries()
    }

    func updateValue(for key: String, newValue: String, type: String) {
        let converted: Any
        switch type {
        case "Int":
            converted = Int(newValue) ?? 0
        case "Double":
            converted = Double(newValue) ?? 0.0
        case "Bool":
            converted = (newValue.lowercased() == "true" || newValue == "1")
        default:
            converted = newValue
        }
        UserDefaults.standard.set(converted, forKey: key)
        loadEntries()
    }

    func deleteKey(_ key: String) {
        UserDefaults.standard.removeObject(forKey: key)
        loadEntries()
    }

    func addEntry(key: String, value: String, type: String) {
        updateValue(for: key, newValue: value, type: type)
    }

    func clearFilteredKeys() {
        if selectedGroup == .all && searchText.isEmpty,
           let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
            UserDefaults.standard.synchronize()
        } else {
            let keys = filteredEntries.map(\.key)
            keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
            UserDefaults.standard.synchronize()
        }
        loadEntries()
    }

    var isEditable: Bool {
        editingEntry != nil
    }

    func startEditing(_ entry: UserDefaultsEntry) {
        editingEntry = entry
    }

    func selectGroup(_ group: GroupFilter) {
        selectedGroup = group
    }

    private func resolveType(_ value: Any) -> (typeLabel: String, displayValue: String, boolValue: Bool?) {
        if let cfValue = value as? NSNumber {
            if CFGetTypeID(cfValue) == CFBooleanGetTypeID() {
                let boolVal = cfValue.boolValue
                return ("Bool", boolVal ? "true" : "false", boolVal)
            }
            if cfValue === (cfValue as? Int).map({ NSNumber(value: $0) }) ?? cfValue,
               floor(cfValue.doubleValue) == cfValue.doubleValue {
                return ("Int", "\(cfValue.intValue)", nil)
            }
            return ("Double", "\(cfValue.doubleValue)", nil)
        }
        if let stringValue = value as? String {
            return ("String", stringValue, nil)
        }
        if let dateValue = value as? Date {
            let formatter = ISO8601DateFormatter()
            return ("Date", formatter.string(from: dateValue), nil)
        }
        if let dataValue = value as? Data {
            return ("Data", "\(dataValue.count) bytes", nil)
        }
        if let arrayValue = value as? [Any] {
            if let data = try? JSONSerialization.data(withJSONObject: arrayValue, options: .fragmentsAllowed),
               let json = String(data: data, encoding: .utf8) {
                return ("Array", json, nil)
            }
            return ("Array", "\(arrayValue.count) items", nil)
        }
        if let dictValue = value as? [String: Any] {
            if let data = try? JSONSerialization.data(withJSONObject: dictValue, options: [.sortedKeys]),
               let json = String(data: data, encoding: .utf8) {
                return ("Dict", json, nil)
            }
            return ("Dict", "\(dictValue.count) keys", nil)
        }
        return ("Unknown", "\(value)", nil)
    }
}
