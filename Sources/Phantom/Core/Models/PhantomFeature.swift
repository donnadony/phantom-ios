import SwiftUI

public enum PhantomFeature: CaseIterable {
    case logs
    case network
    case mockServices
    case configuration
    case deviceInfo
    case userDefaults
    case localization
    case fileBrowser
    case deepLink

    var title: String {
        switch self {
        case .logs: return "Logs"
        case .network: return "Network"
        case .mockServices: return "Mock Services"
        case .configuration: return "Configuration"
        case .deviceInfo: return "Device Info"
        case .userDefaults: return "UserDefaults"
        case .localization: return "Localization"
        case .fileBrowser: return "File Browser"
        case .deepLink: return "Deep Link Tester"
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
        case .fileBrowser: return "folder"
        case .deepLink: return "link"
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
        case .fileBrowser: PhantomFileBrowserView()
        case .deepLink: PhantomDeepLinkView()
        }
    }
}
