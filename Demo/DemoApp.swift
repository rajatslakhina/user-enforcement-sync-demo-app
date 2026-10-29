import SwiftUI
import UserEnforcement
import UserEnforcementUI

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            EnforcementConsoleView(scenario: .demo)
        }
    }
}

/// The compiled-in configuration this app owns: which AI features exist, how risky each one is,
/// how long each may trust a stale "user is in good standing", and the scripted backend timeline.
extension EnforcementScenario {
    static let demo: EnforcementScenario = {
        let user = "user_8f3a"
        let start = Instant(millis: 1_800_000_000_000)
        let capabilities = [
            Capability(id: "summarize", displayName: "Summarize thread", risk: .read, hasOnDeviceFallback: true),
            Capability(id: "draft-reply", displayName: "Draft reply", risk: .generate, hasOnDeviceFallback: true),
            Capability(id: "agent-send", displayName: "Agent sends for you", risk: .act, hasOnDeviceFallback: false),
        ]
        // rev 2: agent actions paused for 20 minutes. rev 3: suspended. rev 4: suspension lifted,
        // agent actions restricted until further notice. The backend's head is rev 4.
        let rev2 = EnforcementSignal(userID: user, revision: 2, restriction: .restricted(["agent-send"]),
                                     expiresAt: start.advanced(byMillis: 20 * 60_000), source: .push)
        let rev3 = EnforcementSignal(userID: user, revision: 3, restriction: .suspended, source: .push)
        let rev4 = EnforcementSignal(userID: user, revision: 4, restriction: .restricted(["agent-send"]), source: .push)
        return EnforcementScenario(
            userID: user,
            startsAt: start,
            capabilities: capabilities,
            policy: .standard,
            serverHead: rev4.withSource(.snapshot),
            // APNs delivers out of order: 3, then the older 2, then 4.
            pushDeliveryOrder: [rev3, rev2, rev4])
    }()
}
