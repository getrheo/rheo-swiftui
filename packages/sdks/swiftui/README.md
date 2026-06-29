# RheoSwiftUI

Native SwiftUI SDK for Rheo onboarding flows. It resolves a dashboard channel,
runs the same flow state machine as the React Native SDK, renders authored
layers in SwiftUI, and emits SDK analytics to Rheo.

## Install

Add this package in Xcode or SwiftPM from the monorepo root, then depend on:

```swift
.product(name: "RheoSwiftUI", package: "RheoSwiftUI")
```

Optional integration products (RevenueCat, AppsFlyer) ship as sibling libraries:

```swift
.product(name: "RheoSwiftUIRevenueCat", package: "RheoSwiftUI"),
.product(name: "RheoSwiftUIAppsFlyer", package: "RheoSwiftUI"),
```

## Minimal usage

```swift
import SwiftUI
import RheoSwiftUI

struct AppRoot: View {
  var body: some View {
    RheoProvider(
      config: RheoConfig(
        publishableKey: "ob_pk_test_xxx",
        userId: "user_123",
        sessionId: "sess_123"
      )
    ) {
      FlowView(channelId: "ch_test_xxx") { snapshot in
        print("completed", snapshot)
      } onFlowAbandoned: { snapshot in
        print("abandoned", snapshot)
      }
    }
  }
}
```

**Production:** `apiBaseURL` defaults to **`https://api.getrheo.io`** when omitted. For App Store builds with **`ob_pk_live_*`** keys, omit the override or set it explicitly — never use localhost.

Release tags: `swiftui-v1.0.0` (see [`docs/operations/artifact-releases.md`](../../docs/operations/artifact-releases.md)).

## Parity with React Native SDK

See [`docs/PARITY_MATRIX.md`](docs/PARITY_MATRIX.md) and [`PARITY_SCOPE.md`](PARITY_SCOPE.md).

| Area | SwiftUI behavior |
| --- | --- |
| Layer kinds | All 22 contract layer kinds |
| Navigation | Instant screen swaps (authored `screen.transition` is ignored) |
| Lottie | `lottie-ios` via `RheoSwiftUILottie`; placeholder on load failure |
| Icons | Bundled Ionicons font + glyph map; unknown name → text fallback |
| Manifest cache | Persistent ETag cache per channel; `If-None-Match` when cached |
| RevenueCat | Default presenter returns `failed`; use `RheoSwiftUIRevenueCat` |
| AppsFlyer | `appsFlyerAttribution: .automatic` when plan + integration enabled (see below) |
| Permissions | Six built-in iOS handlers; other keys → `denied` |
| App review | `request_app_review` via `AppReviewRequester` (StoreKit; ~1.5s delay when prompt may show) |
| CRM id | `RheoRuntime.setCustomUserId(_:)` |

## RevenueCat (optional)

```swift
import RheoSwiftUI
import RheoSwiftUIRevenueCat

FlowView(
  channelId: "ch_xxx",
  externalSurfacePresenter: RheoRevenueCatIntegration.externalSurfacePresenter { config, node in
    // Present paywall with host RevenueCat SDK, then:
    RheoRevenueCatIntegration.normalizePaywallResult("PURCHASED")
  }
)
```

## AppsFlyer (optional)

**Recommended:** link **AppsFlyerLib** in your app target (CocoaPods or SPM), initialize the SDK in the host app (dev key, App Store id, ATT as needed), enable **AppsFlyer** under **App settings → Integrations**, then:

```swift
import RheoSwiftUI
import RheoSwiftUIAppsFlyer

FlowView(
  channelId: "ch_xxx",
  appsFlyerAttribution: .automatic
)
```

Rheo registers `onConversionDataSuccess` and UDL `didResolveDeepLink` when `AppsFlyerLib` is visible to the `RheoSwiftUIAppsFlyer` module (`#if canImport(AppsFlyerLib)`). Payloads map to `acquisition.*`, `link.*`, and `attribution.*` (parity with `@getrheo/react-native-core`).

**Advanced (manual bridge):**

```swift
let appsFlyer = AppsFlyerAttributionProvider { listener in
  // Or forward raw dictionaries:
  // listener(RheoAppsFlyerIntegration.normalizedConversionSnapshot(conversionInfo))
  return { /* unsubscribe */ }
}

FlowView(channelId: "ch_xxx", appsFlyerAttribution: .custom(appsFlyer))
```

## App review (`request_app_review`)

Buttons with **`request_app_review`** submit the screen, invoke **StoreKit** when appropriate, emit **`app_review_prompt_shown`** / **`app_review_prompt_dismissed`** when a prompt may have appeared, record **`app_review:{layerId}`** (`not_shown` or `dismissed`), then follow **`screen.next.default`**.

Apple may not show the sheet (rate limits, TestFlight). There is no reliable dismiss callback on iOS; Rheo waits **~1.5s** after `requestReview()` before advancing when a prompt was attempted.

## Custom fonts (branding)

Resolve may return `branding.fontFamilies` with per-style `url` values. The SDK maps
logical font names from text layers to native PostScript names `RheoFont__{styleId}`
via `RheoFontRegistry.buildFontLoadMap(branding:)` and `resolveFontFamily`.

**The SDK does not download or register branding fonts.** Your app must:

1. Download or bundle each font file referenced by `style.url`.
2. Register faces before rendering text (e.g. `CTFontManagerRegisterFontsForURL` for
   downloaded files, or `UIAppFonts` + bundle resources for shipped fonts).
3. Use the same `RheoFont__{styleId}` names that `buildFontLoadMap` produces when
   registering, so `Font.custom` in text layers resolves correctly.

**Ionicons** are bundled and auto-registered in `RheoProvider` — no host setup.

If a branding font is missing, text layers fall back to the system font (no crash).

```swift
// After resolve (e.g. in your app delegate or after FlowController resolves):
let urls = RheoFontRegistry.buildFontLoadMap(branding: resolved.branding)
for (postScriptName, url) in urls {
  CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
  // Ensure registered family matches postScriptName from buildFontLoadMap.
}
```

## Manifest resolve cache

`RheoAPIClient` caches each successful resolve under
`(apiBaseURL, publishableKey, channelId)` in memory and `UserDefaults`. When a cache
entry exists, the next resolve sends `If-None-Match` with the stored ETag; a `304`
reuses the cached manifest without re-downloading the body. Conditional headers are
**not** sent unless a validated cache entry exists.

## Permissions

Built-in handlers: `notifications`, `camera`, `microphone`, `photo_library`,
`contacts`, `calendar`. All other contract keys (including Android-only keys on
iOS) return `denied` — same as React Native today.

Add the required `Info.plist` usage description strings for each permission you
use in a flow.

## Verification

Requires **Xcode** (iOS Simulator SDK).

```bash
pnpm build:swiftui
pnpm test:swiftui
```

Tests run through `xcodebuild test -scheme RheoSwiftUI-Package` on an iOS Simulator
(see [`scripts/run-swiftui-sdk.mjs`](../../../scripts/run-swiftui-sdk.mjs)).
