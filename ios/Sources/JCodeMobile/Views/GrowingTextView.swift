import SwiftUI
import UIKit

/// iOS 15-compatible multiline composer backed by `UITextView`.
struct GrowingTextView: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let minHeight: CGFloat
    let maxHeight: CGFloat
    @Binding var calculatedHeight: CGFloat

    private static let placeholderTag = 9_115

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        view.font = UIFont.preferredFont(forTextStyle: .body)
        view.adjustsFontForContentSizeCategory = true
        view.textColor = UIColor(Theme.textPrimary)
        view.tintColor = UIColor(Theme.mint)
        view.keyboardAppearance = .dark
        view.textContainerInset = UIEdgeInsets(top: 11, left: 12, bottom: 11, right: 12)
        view.textContainer.lineFragmentPadding = 0
        view.isScrollEnabled = false
        view.showsVerticalScrollIndicator = true
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.accessibilityLabel = "Message"
        view.accessibilityHint = "Enter a message to send"

        let placeholderLabel = UILabel()
        placeholderLabel.tag = Self.placeholderTag
        placeholderLabel.textColor = .placeholderText
        placeholderLabel.font = view.font
        placeholderLabel.adjustsFontForContentSizeCategory = true
        placeholderLabel.isAccessibilityElement = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(placeholderLabel)
        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: view.textContainerInset.left
            ),
            placeholderLabel.topAnchor.constraint(
                equalTo: view.topAnchor,
                constant: view.textContainerInset.top
            ),
            placeholderLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor,
                constant: -view.textContainerInset.right
            ),
        ])

        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        context.coordinator.parent = self
        if view.text != text {
            view.text = text
        }
        updatePlaceholder(in: view)
        DispatchQueue.main.async {
            recalculateHeight(view)
        }
    }

    private func updatePlaceholder(in view: UITextView) {
        guard let label = view.viewWithTag(Self.placeholderTag) as? UILabel else { return }
        label.text = placeholder
        label.isHidden = !text.isEmpty
    }

    fileprivate func recalculateHeight(_ view: UITextView) {
        guard view.bounds.width > 0 else { return }
        let fittingHeight = view.sizeThatFits(
            CGSize(width: view.bounds.width, height: .greatestFiniteMagnitude)
        ).height
        let clampedHeight = min(max(fittingHeight, minHeight), maxHeight)
        let needsScrolling = fittingHeight > maxHeight

        if view.isScrollEnabled != needsScrolling {
            view.isScrollEnabled = needsScrolling
        }
        if abs(calculatedHeight - clampedHeight) > 0.5 {
            calculatedHeight = clampedHeight
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: GrowingTextView

        init(parent: GrowingTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.updatePlaceholder(in: textView)
            parent.recalculateHeight(textView)
        }
    }
}
