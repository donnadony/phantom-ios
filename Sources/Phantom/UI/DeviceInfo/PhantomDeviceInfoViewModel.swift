import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

final class PhantomDeviceInfoViewModel: ObservableObject {

    enum InfoSection: String, CaseIterable {
        case app = "App"
        case device = "Device"
        case storage = "Storage"
        case memory = "Memory"
    }

    struct InfoItem: Identifiable {
        let id = UUID()
        let label: String
        let value: String
        let section: InfoSection
    }

    @Published var items: [InfoItem] = []
    @Published var copiedItemId: UUID?

    init() {
        loadItems()
    }

    func copyValue(_ item: InfoItem) {
        UIPasteboard.general.string = item.value
        copiedItemId = item.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            if self?.copiedItemId == item.id {
                self?.copiedItemId = nil
            }
        }
    }

    func items(for section: InfoSection) -> [InfoItem] {
        items.filter { $0.section == section }
    }

    private func loadItems() {
        items = appItems() + deviceItems() + storageItems() + memoryItems()
    }

    private func appItems() -> [InfoItem] {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "N/A"
        let bundleId = bundle.bundleIdentifier ?? "N/A"
        let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "N/A"
        return [
            InfoItem(label: "Version", value: version, section: .app),
            InfoItem(label: "Build", value: build, section: .app),
            InfoItem(label: "Bundle ID", value: bundleId, section: .app),
            InfoItem(label: "Display Name", value: displayName, section: .app),
        ]
    }

    private func deviceItems() -> [InfoItem] {
        let modelName = resolveModelName()
        let systemVersion = ProcessInfo.processInfo.operatingSystemVersionString
        var screenSize = "N/A"
        var screenScale = "N/A"
        #if canImport(UIKit)
        let screen = UIScreen.main
        screenSize = "\(Int(screen.bounds.width))x\(Int(screen.bounds.height))"
        screenScale = "\(screen.scale)x"
        #endif
        return [
            InfoItem(label: "Model", value: modelName, section: .device),
            InfoItem(label: "iOS Version", value: systemVersion, section: .device),
            InfoItem(label: "Screen Size", value: screenSize, section: .device),
            InfoItem(label: "Screen Scale", value: screenScale, section: .device),
        ]
    }

    private func storageItems() -> [InfoItem] {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB]
        formatter.countStyle = .file
        var totalDisk = "N/A"
        var freeDisk = "N/A"
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            if let total = attrs[.systemSize] as? Int64 {
                totalDisk = formatter.string(fromByteCount: total)
            }
            if let free = attrs[.systemFreeSize] as? Int64 {
                freeDisk = formatter.string(fromByteCount: free)
            }
        }
        return [
            InfoItem(label: "Total Disk", value: totalDisk, section: .storage),
            InfoItem(label: "Free Disk", value: freeDisk, section: .storage),
        ]
    }

    private func memoryItems() -> [InfoItem] {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .memory
        let physicalRam = formatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory))
        let usedMemory = currentUsedMemory(formatter: formatter)
        return [
            InfoItem(label: "Physical RAM", value: physicalRam, section: .memory),
            InfoItem(label: "Used Memory", value: usedMemory, section: .memory),
        ]
    }

    private func currentUsedMemory(formatter: ByteCountFormatter) -> String {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPtr, &count)
            }
        }
        guard result == KERN_SUCCESS else { return "N/A" }
        return formatter.string(fromByteCount: Int64(info.phys_footprint))
    }

    private func resolveModelName() -> String {
        #if targetEnvironment(simulator)
        return ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? machineIdentifier()
        #else
        return marketingName(for: machineIdentifier())
        #endif
    }

    private func machineIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }
    }

    private func marketingName(for identifier: String) -> String {
        let mapping: [String: String] = [
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",
            "iPhone15,4": "iPhone 15",
            "iPhone15,5": "iPhone 15 Plus",
            "iPhone17,1": "iPhone 16 Pro",
            "iPhone17,2": "iPhone 16 Pro Max",
            "iPhone17,3": "iPhone 16",
            "iPhone17,4": "iPhone 16 Plus",
            "iPhone17,5": "iPhone 16e",
            "iPad16,3": "iPad Pro 13-inch (M4)",
            "iPad16,4": "iPad Pro 13-inch (M4)",
            "iPad16,5": "iPad Pro 11-inch (M4)",
            "iPad16,6": "iPad Pro 11-inch (M4)",
        ]
        return mapping[identifier] ?? identifier
    }
}
