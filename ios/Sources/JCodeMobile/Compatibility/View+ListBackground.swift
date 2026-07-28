import SwiftUI

extension View {
    /// Preserves the upstream transparent list style where the API exists;
    /// iOS 15 keeps its native list background.
    @ViewBuilder
    func hideListBackgroundWhenAvailable() -> some View {
        if #available(iOS 16.0, *) {
            scrollContentBackground(.hidden)
        } else {
            self
        }
    }
}