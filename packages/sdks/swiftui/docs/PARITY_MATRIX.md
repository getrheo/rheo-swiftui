# React Native ↔ SwiftUI parity matrix

| React Native (`@getrheo/react-native-expo` / bare) | SwiftUI (`RheoSwiftUI`) | Notes |
| --- | --- | --- |
| `RheoProvider` | `RheoProvider` | Swift-native config object |
| `useRheo` | `@Environment(\.rheoRuntime)` | No React hook equivalent |
| `useRheoCustomUserId` | `RheoRuntime.setCustomUserId(_:)` | Applied at event flush |
| `useEventQueue` | `RheoRuntime.eventQueue` | Internal; same batching semantics |
| `useFlow` | `FlowController` + `FlowView` | Channel resolve + state machine |
| `Flow` | `FlowView` | Instant screen swaps (no between-screen transitions) |
| `LayerRenderer` | `SwiftUILayerRenderer` | All 22 layer kinds |
| `AnimatedScreenSwitch` | — | Removed; parity uses instant navigation |
| `MotionProvider` / `LayerMotionShell` | `MotionController` / `LayerMotionShell` | Layer clips + resting only |
| `ScreenChrome` | `ScreenChrome` | Keyboard avoidance only; host applies safe area |
| `OAuthLoginProvider` / `useOAuthLogin` | `onOAuthLogin` on `FlowView` | Host-owned OAuth |
| `EmailPasswordAuthProvider` | `onEmailPasswordAuth` | Host-owned credentials |
| `presentRevenueCatPaywall` | `RheoSwiftUIRevenueCat` optional product | Host wires RevenueCat SDK |
| `iap_purchase` event (RN auto-extracts via `react-native-purchases`) | `iap_purchase` event (host populates `RevenueCatPurchaseCommerce` via `RheoRevenueCatIntegration.normalizePaywallResult(_:commerce:)`) | Host reads `productIdentifier` / `StoreProduct` price from RevenueCat Swift SDK |
| `createAttributionRuntime` / AppsFlyer | `RheoSwiftUIAppsFlyer` + `appsFlyerAttribution: .automatic` (or manual `attributionProviders`) | Plan + integration gated; RN-aligned payload normalizer |
| `buildBrandingFontLoadMap` | `RheoFontRegistry.buildFontLoadMap` | Host registers fonts |
| `initFlowState`, `submitResponse`, … | Same-named Swift functions | Ported in `FlowRuntime.swift` |
| `FlowTerminalSnapshot` | `FlowTerminalSnapshot` | Same schema version |
| Lottie (`lottie-react-native`) | `BundledLottieRenderer` + `lottie-ios` | Placeholder on load failure |
| Icons (Ionicons) | `RheoIconRenderer` + bundled Ionicons font | Ionicons-only; unknown name → text fallback |
| OS permissions (6 keys) | `OSPermissionRequester` | Other keys → `denied` |
| `request_app_review` button | `AppReviewRequester` + `app_review_prompt_*` events | StoreKit; ~1.5s post-prompt delay on iOS |
| Android-only permission keys | `denied` on iOS | By design |
| Manifest resolve cache (ETag / 304) | `manifestResolveCache` + `resolveManifest` | `ManifestResolveCache` + `RheoAPIClient` |
| Resolve-failure fallback | `Flow` `fallback` prop; `DefaultResolveError`; `resolveFailed` + `retry()` on `useFlow` | `FlowView` `fallback` builder; `DefaultResolveErrorView`; `FlowController.resolveFailed` + `retry()` |
| Persistent event queue | — | Not in parity wave |
| Web platform | — | SwiftUI is iOS-only |

