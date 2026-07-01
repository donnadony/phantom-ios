import Testing
@testable import Phantom

@Suite("PhantomConfig group ordering")
struct PhantomConfigTests {

    @Test("groups preserve first-seen registration order")
    func groupsFollowRegistrationOrder() {
        let config = PhantomConfig.shared
        config.register("A", key: "test_k_ff", defaultValue: "false", type: .toggle, group: "Feature Flag")
        config.register("B", key: "test_k_nav", defaultValue: "false", type: .toggle, group: "Navigation Migration")
        config.register("C", key: "test_k_app", defaultValue: "false", type: .toggle, group: "App Configuration")
        let ordered = ["Feature Flag", "Navigation Migration", "App Configuration"]
        let filtered = config.groups.filter { ordered.contains($0) }
        #expect(filtered == ordered)
    }

}
