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
| `ios/project.yml` | 4–5 | deployment target 17.0 | n/a | Set generated app deployment target to 15.0 | Complete |
| `ios/Package.swift` | 6–8 | `.iOS(.v17)` | n/a | Set package platform to `.iOS(.v15)`; keep macOS 14 | Complete |
| `AppModel.swift` | 3, 11 | Observation / `@Observable` | 17 | `ObservableObject` plus `@Published`; preserve reducer and transport behavior | Complete |
| `JCodeMobileApp.swift` | 5, 11 | Observation ownership and `.environment(model)` | 17 | `@StateObject` plus `.environmentObject(model)` | Complete |
| `RootView.swift` | 6 | `@Environment(AppModel.self)` | 17 | `@EnvironmentObject var model: AppModel` | Complete |
| `ChatView.swift` | 6, 12, 52 | Observation environment / `@Bindable` | 17 | Environment object and explicit `Binding(get:set:)` for `draft` | Complete |
| `PairingView.swift` | 6 | `@Environment(AppModel.self)` | 17 | Environment object | Complete |
| `SettingsView.swift` | 6 | `@Environment(AppModel.self)` | 17 | Environment object | Complete |
| `SettingsSections.swift` | 6, 90, 146 | `@Environment(AppModel.self)` | 17 | Environment object | Complete |
| `JCodeMobileApp.swift` | 14 | two-argument `onChange` closure | 17 | one-argument iOS 15 closure | Complete |
| `SettingsView.swift` | 57 | zero-argument `onChange` closure | 17 | one-argument closure, ignore value | Complete |
| `TranscriptView.swift` | 70, 74 | zero-argument `onChange` closures | 17 | one-argument closures, ignore values | Complete |
| `SettingsView.swift` | 16, 46 | `NavigationStack` | 16 | `NavigationView` with `StackNavigationViewStyle` | Complete |
| `Composer.swift` | 14–19 | vertically growing `TextField(axis:)` and ranged line limit | 16 | local `UITextView`/`UIViewRepresentable` growing composer | Complete |
| `PairingView.swift` | 83 | `scrollDismissesKeyboard` | 16 | one compatibility view modifier using drag-to-resign-first-responder | Complete |
| `TranscriptView.swift` | 61 | `scrollDismissesKeyboard` | 16 | same shared compatibility modifier | Complete |
| `SettingsView.swift` | 26 | `scrollContentBackground` | 16 | remove; keep row backgrounds, add one scoped UIKit fallback only if visually required | Complete |
| `ChatView.swift` | 65–70 | `sensoryFeedback` | 17 | UIKit feedback generators triggered at existing state transitions | Complete |

## Compiler-gated risks — do not change speculatively

| File | Line(s) | Construct | Compiler result |
|---|---:|---|---|
| `Theme.swift` | 58–60 | SwiftUI `@Entry` environment declaration | Accepted by the iOS 15 deployment build; preserved unchanged. |
| `TranscriptView.swift` | 62–68 | `MainActor.assumeIsolated` inside preference callback | Accepted by the iOS 15 deployment build; pinning behavior preserved unchanged. |
| `ToolCallCard.swift` / `TranscriptView.swift` | progress views | `.controlSize(.mini/.small)` | Accepted by the iOS 15 deployment build; preserved unchanged. |
| `PairingView.swift` | 31–32 | input capitalization/autocorrection modifiers | Accepted by the iOS 15 deployment build; preserved unchanged. |

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
- `URLSessionWebSocketTask`, Security/Keychain, Codable, actors, and async streams in JCodeKit

No occurrences were found for `ContentUnavailableView`, `presentationDetents`, `NavigationSplitView`, `ShareLink`, `PhotosPicker`, `ViewThatFits`, `AnyLayout`, `Grid`, `symbolEffect`, scroll-target APIs, or other obvious iOS 16/17-only UI families.

## JCodeKit boundary

The final source diff contains no changes in `ios/Sources/JCodeKit` or `ios/Tests/JCodeKitTests`. Only the package deployment declaration moved to iOS 15. Pairing, keychain storage, WebSocket transport, connection actor, wire types, reducer semantics, and server protocol remain unchanged. All 71 JCodeKit tests pass with the iOS 15 package declaration.

## Recorded compiler evidence

- Unmodified upstream baseline: [Actions run 30378214285](https://github.com/robbyczgw-cla/jcode/actions/runs/30378214285) — tests, XcodeGen, and unsigned simulator build passed.
- First iOS 15 target build: [Actions run 30378471209](https://github.com/robbyczgw-cla/jcode/actions/runs/30378471209) — JCodeKit tests passed; the app failed on the expected Observation availability diagnostics.
- Final compatibility source commit: `efbbe29828a047fc254b674757d4255eb1eaff05`.
- Final iOS 15 gate: [Actions run 30380711472](https://github.com/robbyczgw-cla/jcode/actions/runs/30380711472) — 71 tests passed, XcodeGen succeeded, and the unsigned app build succeeded.
- Generated build settings contain only `IPHONEOS_DEPLOYMENT_TARGET = 15.0`.
- Runner toolchain: macOS 26.4, Xcode 26.5 (`17F42`), Swift 6.3.2.
- Downloaded evidence is retained locally under `artifacts/backport-baseline/`, `artifacts/ios15-first-build.txt`, and `artifacts/ios15-green/` (excluded from Git history).

## iPhone SE1 layout risks

- `ChatView` uses 16 pt outer padding plus title, status, and a 44 pt settings button in one row; model text needs conditional suppression or stronger truncation at 320 pt.
- `Composer` can show both Stop and Send buttons; the growing text view must take the remaining width and outer horizontal padding should be reduced to 10–12 pt on compact widths.
- Pairing currently adds 32 pt top padding and 20 pt vertical spacing; verify keyboard-visible operation at 568 pt height.
- Settings rows already use truncation in several places, but model/server/session labels need a real 320 pt screenshot review.
- Existing 44 × 44 pt interaction targets should not be reduced.

## Validation gates

1. **Complete:** unmodified-source baseline with `swift test`, XcodeGen generation, and unsigned generic simulator build.
2. **Complete:** target-lowering failure build and compiler-driven compatibility sequence.
3. **Complete for current compatibility source:** `git diff --check`, 71 JCodeKit tests, generated target verification, and unsigned app build.
4. **Pending hardware:** signed install and hands-on smoke test on a real iPhone SE1 with iOS 15.
5. A modern simulator build is necessary but not sufficient: availability checking comes from the deployment target, while SE1 performance/layout and iOS 15 runtime behavior require the real device.
