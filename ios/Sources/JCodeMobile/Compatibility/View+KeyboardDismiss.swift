import SwiftUI
import UIKit

extension View {
    /// Keeps native interactive dismissal on iOS 16+ and falls back to a
    /// simultaneous drag gesture on iOS 15.
    @ViewBuilder
    func dismissKeyboardOnScroll() -> some View {
        if #available(iOS 16.0, *) {
            scrollDismissesKeyboard(.interactively)
        } else {
            dismissKeyboardOnDrag()
        }
    }

    private func dismissKeyboardOnDrag() -> some View {
        simultaneousGesture(
            DragGesture(minimumDistance: 8)
                .onChanged { _ in
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
        )
    }
}
