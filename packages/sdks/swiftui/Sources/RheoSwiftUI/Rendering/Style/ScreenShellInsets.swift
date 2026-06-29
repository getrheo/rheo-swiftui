import Foundation

private func paddingEdgeSum(_ a: Double?, _ b: Double?) -> Double? {
  let sum = (a ?? 0) + (b ?? 0)
  return sum == 0 ? nil : sum
}

func addPadding(_ a: Padding?, _ b: Padding?) -> Padding? {
  guard a != nil || b != nil else { return nil }
  var out = Padding()
  out.t = paddingEdgeSum(a?.t, b?.t)
  out.r = paddingEdgeSum(a?.r, b?.r)
  out.b = paddingEdgeSum(a?.b, b?.b)
  out.l = paddingEdgeSum(a?.l, b?.l)
  let hasAny = out.t != nil || out.r != nil || out.b != nil || out.l != nil
  return hasAny ? out : nil
}

func resolveEffectiveScreenShellPadding(
  manual: Padding?,
  insetSafeArea: Bool?,
  safeAreaInsets: Padding
) -> Padding? {
  guard insetSafeArea == true else { return manual }
  return addPadding(manual, safeAreaInsets)
}
