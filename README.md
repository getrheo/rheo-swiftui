# rheo-swiftui

Public home for **RheoSwiftUI** — the native SwiftUI SDK for iOS 16+ (channel resolve, `FlowView`, analytics, optional RevenueCat and AppsFlyer adapters).

## SwiftPM products

| Product | Purpose |
| --- | --- |
| `RheoSwiftUI` | Core provider, flow host, renderer |
| `RheoSwiftUIRevenueCat` | RevenueCat paywall adapter (optional) |
| `RheoSwiftUIAppsFlyer` | AppsFlyer attribution adapter (optional) |

Package manifest: `packages/sdks/swiftui/Package.swift`.

**Release:** git tag `swiftui-v2.1.0` (not npm). Pin the tag in your app's `Package.swift` or use the [example app](https://github.com/getrheo/rheo-example-swiftui) submodule layout.

`apiBaseURL` defaults to `https://api.getrheo.io` when omitted.

## Example app

[rheo-example-swiftui](https://github.com/getrheo/rheo-example-swiftui) — config screen + `FlowView`, mirrors the Expo sample.

## Development

Requires **Xcode** with an iOS Simulator runtime.

```bash
pnpm install
pnpm build:swiftui
pnpm test:swiftui
```

[Documentation](https://docs.getrheo.io/docs/developer-guide/sdk-swiftui) · [CONTRIBUTING](./CONTRIBUTING.md) · [MIT](./LICENSE)
