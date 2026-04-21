import SwiftUI

struct SelectedTabKey: EnvironmentKey {
    static let defaultValue: String = "ForYou"
}

struct OwningTabKey: EnvironmentKey {
    static let defaultValue: String = "Unknown"
}

extension EnvironmentValues {
    var selectedTab: String {
        get { self[SelectedTabKey.self] }
        set { self[SelectedTabKey.self] = newValue }
    }
    
    var owningTab: String {
        get { self[OwningTabKey.self] }
        set { self[OwningTabKey.self] = newValue }
    }
}
