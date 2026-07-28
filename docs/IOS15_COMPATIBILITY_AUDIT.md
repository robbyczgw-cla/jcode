# iOS 15 Compatibility Audit

## Scope and provenance

- Upstream: `1jehuang/jcode`
- Audited source commit: `a3a24cdb3aee97ebb43fe84e79bfa63828f3a39a`
- Backport branch: `ios15-se1-backport`
- Target device: iPhone SE (1st generation), 320 × 568 pt, iOS 15
- Architecture constraint: keep `JCodeMobile → AppModel → JCodeKit → JCode server`; no wire-protocol changes
- Baseline compiler gate: unsigned macOS/Xcode GitHub Actions workflow `ios-compatibility.yml`

This document distinguishes confirmed availability failures from compiler-gated risks. APIs that already support iOS 15 are intentionally left alone.

## Confirmed compatibility work

| File | Line(s) at audited commit | API / construct | Minimum iOS | Minimal replacement | Status |
|---|---:|---|---:|---|---|
| `ios/project.yml` | 4–5 | deployment target 17.0 | n/a | Set generated app deployment target to 15.0 | Pending |
| `ios/Package.swift` | 6–8 | `.iOS(.v17)` | n/a | Set package platform to `.iOS(.v15)`; keep macOS 14 | Pending |
| `AppModel.swift` | 3, 11 | Observation / `@Observable` | 17 | `ObservableObject` plus `@Published`; preserve reducer and transport behavior | Pending |
| `JCodeMobileApp.swift` | 5, 11 | Observation ownership and `.environment(model)` | 17 | `@StateObject` plus `.environmentObject(model)` | Pending |
| `RootView.swift` | 6 | `@Environment(AppModel.self)` | 17 | `@EnvironmentObject var model: AppModel` | Pending |
| `ChatView.swift` | 6, 12, 52 | Observation environment / `@Bindable` | 17 | Environment object and explicit `Binding(get:set:)` for `draft` | Pending |
| `PairingView.swift` | 6 | `@Environment(AppModel.self)` | 17 | Environment object | Pending |
| `SettingsView.swift` | 6 | `@Environment(AppModel.self)` | 17 | Environment object | Pending |
| `SettingsSections.swift` | 6, 90, 146 | `@Environment(AppModel.self)` | 17 | Environment object | Pending |
| `JCodeMobileApp.swift` | 14 | two-argument `onChange` closure | 17 | one-argument iOS 15 closure | Pending |
| `SettingsView.swift` | 57 | zero-argument `onChange` closure | 17 | one-argument closure, ignore value | Pending |
| `TranscriptView.swift` | 70, 74 | zero-argument `onChange` closures | 17 | one-argument closures, ignore values | Pending |
| `SettingsView.swift` | 16, 46 | `NavigationStack` | 16 | `NavigationView` with `StackNavigationViewStyle` | Pending |
| `Composer.swift` | 14–19 | vertically growing `TextField(axis:)` and ranged line limit | 16 | local `UITextView`/`UIViewRepresentable` growing composer | Pending |
| `PairingView.swift` | 83 | `scrollDismissesKeyboard` | 16 | one compatibility view modifier using drag-to-resign-first-responder | Pending |
| `TranscriptView.swift` | 61 | `scrollDismissesKeyboard` | 16 | same shared compatibility modifier | Pending |
| `SettingsView.swift` | 26 | `scrollContentBackground` | 16 | remove; keep row backgrounds, add one scoped UIKit fallback only if visually required | Pending |
| `ChatView.swift` | 65–70 | `sensoryFeedback` | 17 | UIKit feedback generators triggered at existing state transitions | Pending |

## Compiler-gated risks — do not change speculatively

| File | Line(s) | Construct | Current strategy |
|---|---:|---|---|
| `Theme.swift` | 58–60 | SwiftUI `@Entry` environment declaration | Try the iOS 15 deployment build first. If unavailable, replace only this declaration with an explicit private `EnvironmentKey`; callers remain unchanged. |
| `TranscriptView.swift` | 62–68 | `MainActor.assumeIsolated` inside preference callback | Keep if the deployment build accepts it. Otherwise dispatch the state mutation to the main queue without deleting pinning behavior. |
| `ToolCallCard.swift` / `TranscriptView.swift` | progress views | `.controlSize(.mini/.small)` | Build-gated. Preserve unless Xcode reports an availability error. |
| `PairingView.swift` | 31–32 | input capitalization/autocorrection modifiers | Expected to support iOS 15; change only on a concrete compiler error. |

## APIs verified as compatible with iOS 15

The following matched the broad scan but should remain:

- `@Environment(\.dismiss)`
- `.task`, `.onOpenURL`, `.ignoresSafeArea`
- `.foregroundStyle` with the current color overloads
- `.dynamicTypeSize`
- `.textSelection(.enabled)`
- `.tint`
- Swift `AttributedString` markdown parsing
- `UIViewControllerRepresentable`, AVFoundation QR capture, and UIKit feedback generators
- SwiftUI sheet, alert, toolbar, and `ToolbarItem` forms currently used
- `URLSessionWebSocketTask`, Security/Keychain, Codable, actors, and async streams in JCodeKit, subject to the deployment compiler gate

No occurrences were found for `ContentUnavailableView`, `presentationDetents`, `NavigationSplitView`, `ShareLink`, `PhotosPicker`, `ViewThatFits`, `AnyLayout`, `Grid`, `symbolEffect`, scroll-target APIs, or other obvious iOS 16/17-only UI families.

## JCodeKit boundary

Initial source inspection found no reason to move UI compatibility code into `JCodeKit`. The package deployment declaration must move to iOS 15, but pairing, keychain storage, WebSocket transport, connection actor, wire types, and reducer semantics should remain unchanged unless the real compiler or tests identify a concrete issue.

## iPhone SE1 layout risks

- `ChatView` uses 16 pt outer padding plus title, status, and a 44 pt settings button in one row; model text needs conditional suppression or stronger truncation at 320 pt.
- `Composer` can show both Stop and Send buttons; the growing text view must take the remaining width and outer horizontal padding should be reduced to 10–12 pt on compact widths.
- Pairing currently adds 32 pt top padding and 20 pt vertical spacing; verify keyboard-visible operation at 568 pt height.
- Settings rows already use truncation in several places, but model/server/session labels need a real 320 pt screenshot review.
- Existing 44 × 44 pt interaction targets should not be reduced.

## Validation gates

1. Unmodified-source baseline: `swift test`, XcodeGen generation, unsigned generic simulator build.
2. After target lowering: repeat the same gates and treat compiler diagnostics as the authoritative patch list.
3. After each compatibility commit: `git diff --check`, JCodeKit tests, unsigned app build.
4. Before device claim: signed install and hands-on smoke test on a real iPhone SE1 with iOS 15.
5. A modern simulator build is necessary but not sufficient: availability checking comes from the deployment target, while SE1 performance/layout and iOS 15 runtime behavior require the real device.
