# SwiftUI / React Native parity scope

Locked for the parity remediation branch:

- **Platform:** iOS 16+ only (`RheoSwiftUI`).
- **Parity target:** behavioral, public API, and close visual parity with `@getrheo/react-native-expo` / `@getrheo/react-native-bare`.
- **Screen navigation:** instant screen swaps; authored `screen.transition` is ignored at runtime (layer animations only).
- **Reduced motion:** no animation-specific reduced-motion policy in the SDK; unrelated accessibility (labels, Dynamic Type) remains.
- **Permissions:** six built-in handlers (`notifications`, `camera`, `microphone`, `photo_library`, `contacts`, `calendar`); all other contract keys return `denied`.
- **Offline:** in-memory event batching only; no persistent queue or manifest cache in this wave.
- **Visual UI:** Lottie and icon rendering ship in the core SDK target.
- **Business integrations:** RevenueCat and AppsFlyer are optional SwiftPM products with first-party adapters.
- **Migration:** none; SwiftUI is treated as a greenfield 0.1.x surface.

See `docs/PARITY_MATRIX.md` for export-by-export mapping.
