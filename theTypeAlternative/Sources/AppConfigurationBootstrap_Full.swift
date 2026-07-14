import Foundation
import AppServices
import FullAppConfiguration

/// Bootstrap for Full variant - initializes FullAppConfiguration
/// This file is ONLY included in theTypeAlternative target
@MainActor
final class AppConfigurationBootstrap {
    static func initialize() {
        FullAppConfiguration.initialize()
        print("✅ FullAppConfiguration initialized (Full variant)")
    }
}
