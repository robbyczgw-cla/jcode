import SwiftUI
import UIKit

extension View {
    /// iOS 15 replacement for `scrollDismissesKeyboard(.interactively)`.
    /// Keeps the scroll gesture intact while resigning the active text input.
    func dismissKeyboardOnDrag() -> some View {
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
