import SwiftUI

public enum PhantomFeature: CaseIterable {
    case logs
    case network
    case mockServices
    case configuration
    case deviceInfo
    case userDefaults
    case localization

    var title: String {
        switch self {
        case .logs: return "Logs"
        case .network: return "Network"
        case .mockServices: return "Mock Services"
        case .configuration: return "Configuration"
        case .deviceInfo: return "Device Info"
        case .userDefaults: return "UserDefaults"
        case .localization: return "Localization"
        }
    }

    var icon: String {
        switch self {
        case .logs: return "doc.text"
        case .network: return "network"
        case .mockServices: return "antenna.radiowaves.left.and.right"
        case .configuration: return "gearshape"
        case .deviceInfo: return "iphone"
        case .userDefaults: return "externaldrive"
        case .localization: return "globe"
        }
    }

    @ViewBuilder
    var destinationView: some View {
        switch self {
        case .logs: PhantomLogsView()
        case .network: PhantomNetworkView()
        case .mockServices: PhantomMockListView()
        case .configuration: PhantomConfigView()
        case .deviceInfo: PhantomDeviceInfoView()
        case .userDefaults: PhantomUserDefaultsView()
        case .localization: PhantomLocalizationView()
        }
    }
}
