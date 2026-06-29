import CoreGraphics

/// Per-kind layout scalar defaults applied when a manifest omits `gap` or a
/// feedback layer's pixel dimensions.
///
/// These mirror `packages/flow-runtime/src/layout/scalarLayoutDefaults.ts`.
/// Server-side ingress normalization backfills these values, so they act as a
/// rendering safety net for sparse manifests. Keep the two sources in sync.
enum LayoutScalarDefaults {
  // Child spacing (px). `gap` fields decode as `Double` in the models.
  static let stackGap: Double = 12
  static let choiceGap: Double = 8
  static let buttonGap: Double = 8
  static let authGap: Double = 8
  static let oauthProviderGap: Double = 8
  static let hyperlinkGap: Double = 0

  // Feedback dimensions (px). `strokeWidth` decodes as `Int`.
  static let progressLinearHeight: CGFloat = 6
  static let loaderLinearHeight: CGFloat = 6
  static let loaderCircularSize: CGFloat = 48
  static let loaderStrokeWidth = 4
}
