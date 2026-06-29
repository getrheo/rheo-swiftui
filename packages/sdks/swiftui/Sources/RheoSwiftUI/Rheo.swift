import SwiftUI

/// Rheo SwiftUI SDK entrypoint.
///
/// The package mirrors the React Native SDK's channel resolve, flow runtime,
/// event queue, terminal snapshots, and native renderer while keeping optional
/// third-party SDKs behind host-provided adapters.
public enum Rheo {
  public static let sdkName = "rheo-swiftui"
  public static let sdkVersion = "0.1.0"
}
