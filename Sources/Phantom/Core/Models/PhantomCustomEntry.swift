import Foundation

public struct PhantomCustomEntry: Identifiable {
    public let id = UUID()
    public let title: String
    public let icon: String
    public let action: () -> Void
}
