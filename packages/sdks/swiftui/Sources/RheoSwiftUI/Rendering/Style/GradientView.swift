import SwiftUI

public let brandGradientPrefix = "$brandGradient:"

public func brandGradient(for themedColor: ThemedColor?, branding: Branding?, mode: ThemeMode) -> BrandGradient? {
  guard let raw = themedColor?.resolve(mode), raw.hasPrefix(brandGradientPrefix) else { return nil }
  let id = String(raw.dropFirst(brandGradientPrefix.count))
  return branding?.gradientPresets.first { $0.id == id }
}

public struct BrandGradientView: View {
  public var gradient: BrandGradient

  public init(gradient: BrandGradient) {
    self.gradient = gradient
  }

  public var body: some View {
    if gradient.type == "linear" {
      LinearGradient(
        stops: gradient.stops.map {
          Gradient.Stop(color: .rheo($0.color), location: $0.offset)
        },
        startPoint: startPoint(angle: gradient.angle ?? 180),
        endPoint: endPoint(angle: gradient.angle ?? 180)
      )
    } else {
      RadialGradient(
        stops: gradient.stops.map {
          Gradient.Stop(color: .rheo($0.color), location: $0.offset)
        },
        center: .center,
        startRadius: 0,
        endRadius: 240
      )
    }
  }
}

private func startPoint(angle: Double) -> UnitPoint {
  let radians = angle * .pi / 180
  let ux = sin(radians)
  let uy = -cos(radians)
  return UnitPoint(x: 0.5 - ux * 0.5, y: 0.5 - uy * 0.5)
}

private func endPoint(angle: Double) -> UnitPoint {
  let radians = angle * .pi / 180
  let ux = sin(radians)
  let uy = -cos(radians)
  return UnitPoint(x: 0.5 + ux * 0.5, y: 0.5 + uy * 0.5)
}
