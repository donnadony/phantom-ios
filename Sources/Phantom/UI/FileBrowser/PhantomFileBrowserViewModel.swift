import Foundation
import SwiftUI

final class PhantomFileBrowserViewModel: ObservableObject {

    struct FileItem: Identifiable {
        let id = UUID()
        let name: String
        let url: URL
        let isDirectory: Bool
        let size: Int64
        let modifiedDate: Date?
    }

    @Published var items: [FileItem] = []
    @Published var previewContent: String?
    @Published var previewTitle: String = ""
    @Published var showPreview = false
    @Published var errorMessage: String?

    let directory: URL
    let title: String

    private let fileManager = FileManager.default

    init(directory: URL? = nil, title: String? = nil) {
        if let directory = directory {
            self.directory = directory
            self.title = title ?? directory.lastPathComponent
        } else {
            self.directory = URL(fileURLWithPath: NSHomeDirectory())
            self.title = title ?? "Sandbox"
        }
        loadContents()
    }

    var isRoot: Bool {
        directory.path == NSHomeDirectory()
    }

    func loadContents() {
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
            items = contents
                .map { url in
                    let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                    return FileItem(
                        name: url.lastPathComponent,
                        url: url,
                        isDirectory: values?.isDirectory ?? false,
                        size: Int64(values?.fileSize ?? 0),
                        modifiedDate: values?.contentModificationDate
                    )
                }
                .sorted { lhs, rhs in
                    if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory }
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
        } catch {
            items = []
            errorMessage = error.localizedDescription
        }
    }

    func deleteItem(_ item: FileItem) {
        do {
            try fileManager.removeItem(at: item.url)
            loadContents()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func previewFile(_ item: FileItem) {
        let ext = item.url.pathExtension.lowercased()
        guard ext == "json" || ext == "plist" else {
            previewContent = "Preview not available for .\(ext) files"
            previewTitle = item.name
            showPreview = true
            return
        }
        do {
            if ext == "json" {
                let data = try Data(contentsOf: item.url)
                let json = try JSONSerialization.jsonObject(with: data)
                let pretty = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
                previewContent = String(data: pretty, encoding: .utf8)
            } else {
                let data = try Data(contentsOf: item.url)
                if let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? Any {
                    previewContent = String(describing: plist)
                }
            }
        } catch {
            previewContent = "Error reading file: \(error.localizedDescription)"
        }
        previewTitle = item.name
        showPreview = true
    }

    func canPreview(_ item: FileItem) -> Bool {
        let ext = item.url.pathExtension.lowercased()
        return ext == "json" || ext == "plist"
    }

    func formattedSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }

    func iconName(for item: FileItem) -> String {
        if item.isDirectory { return "folder.fill" }
        switch item.url.pathExtension.lowercased() {
        case "json": return "doc.text"
        case "plist": return "list.bullet.rectangle"
        case "sqlite", "db": return "cylinder"
        case "png", "jpg", "jpeg", "gif": return "photo"
        case "log", "txt": return "doc.plaintext"
        default: return "doc"
        }
    }
}
