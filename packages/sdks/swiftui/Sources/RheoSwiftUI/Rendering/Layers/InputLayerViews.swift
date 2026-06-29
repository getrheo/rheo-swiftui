import SwiftUI
import UIKit

struct CheckboxLayerView: View {
  @EnvironmentObject private var checkbox: CheckboxAckStore
  var layer: CheckboxLayer
  var ctx: LayerRendererContext

  var body: some View {
    let checked = checkbox.checked[layer.fieldKey] ?? false
    Button {
      checkbox.toggle(layer.fieldKey)
    } label: {
      ZStack {
        RoundedRectangle(cornerRadius: CGFloat((checked ? layer.checkedStyle?.radiusPx : layer.uncheckedStyle?.radiusPx) ?? 4))
          .fill(resolveColor((checked ? layer.checkedStyle?.background : layer.uncheckedStyle?.background), theme: ctx.manifest.theme, mode: ctx.theme, fallback: checked ? .raw("#0a0a0a") : .raw("transparent")))
          .frame(width: CGFloat((checked ? layer.checkedStyle?.sizePx : layer.uncheckedStyle?.sizePx) ?? 22), height: CGFloat((checked ? layer.checkedStyle?.sizePx : layer.uncheckedStyle?.sizePx) ?? 22))
          .overlay(RoundedRectangle(cornerRadius: 4).stroke(.secondary, lineWidth: 1))
        if checked {
          Image(systemName: "checkmark")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(resolveColor(layer.checkedStyle?.checkColor, theme: ctx.manifest.theme, mode: ctx.theme, fallback: .raw("#ffffff")))
        }
      }
    }
    .buttonStyle(.plain)
    .disabled(!ctx.interactive)
    .accessibilityLabel(layer.name ?? "Checkbox")
    .accessibilityValue(checked ? "Checked" : "Unchecked")
    .rheoCommonStyle(
      resolveCommonStyleAtWidth(layer.style, layer.styleBreakpoints, width: ctx.previewWidthPx),
      ctx: ctx,
      containerWidth: CGFloat(ctx.previewWidthPx)
    )
  }
}

struct TextInputLayerView: View {
  @EnvironmentObject private var draft: ScreenInputDraftStore
  var layer: TextInputLayer
  var ctx: LayerRendererContext

  var textBinding: Binding<String> {
    Binding {
      if case .text(let value)? = draft.draft { return value }
      return ""
    } set: { next in
      draft.draft = next.isEmpty ? nil : .text(next)
    }
  }

  var body: some View {
    let placeholder = layer.placeholder?.resolve(locale: ctx.locale) ?? ""
    VStack(alignment: .leading, spacing: 8) {
      ForEach(layer.children ?? [], id: \.id) { child in
        renderChild(child, ctx: ctx)
      }
      if layer.inputType == "multiline" {
        TextEditor(text: textBinding)
          .frame(minHeight: 96)
      } else {
        SecureOrPlainTextField(layer: layer, placeholder: placeholder, text: textBinding)
      }
    }
    .textFieldStyle(.roundedBorder)
    .disabled(!ctx.interactive)
    .rheoCommonStyle(layer.style, ctx: ctx, containerWidth: CGFloat(ctx.previewWidthPx))
  }
}

private struct SecureOrPlainTextField: View {
  var layer: TextInputLayer
  var placeholder: String
  @Binding var text: String

  var body: some View {
    if layer.classification == "sensitive" {
      SecureField(placeholder, text: $text)
        .textInputAutocapitalization(layer.inputType == "email" ? .never : .sentences)
        .keyboardType(keyboard)
    } else {
      TextField(placeholder, text: $text)
        .textInputAutocapitalization(layer.inputType == "email" ? .never : .sentences)
        .keyboardType(keyboard)
    }
  }

  private var keyboard: UIKeyboardType {
    if layer.inputType == "email" { return .emailAddress }
    if layer.inputType == "phone" { return .phonePad }
    if layer.inputType == "url" { return .URL }
    return .default
  }
}

struct ScaleInputLayerView: View {
  @EnvironmentObject private var draft: ScreenInputDraftStore
  var layer: ScaleInputLayer
  var ctx: LayerRendererContext

  var value: Binding<Double> {
    Binding {
      if case .scale(let value)? = draft.draft { return value }
      return snapScaleValue(layer, layer.defaultValue ?? layer.min)
    } set: { next in
      draft.draft = .scale(snapScaleValue(layer, next))
    }
  }

  private var showEndLabels: Bool { layer.showLabels ?? true }
  private var showSelectedValue: Bool { layer.showValue ?? true }

  private func textColor(_ style: ScaleInputLabelStyle?, fallback: ThemedColor) -> Color {
    resolveColor(style?.color, theme: ctx.manifest.theme, mode: ctx.theme, fallback: fallback)
  }

  private func textFont(_ style: ScaleInputLabelStyle?, defaultSize: CGFloat, defaultWeight: Int?) -> Font {
    let size = CGFloat(style?.fontSize ?? defaultSize)
    let weight = rheoFontWeight(style?.fontWeight ?? defaultWeight)
    if let family = RheoFontRegistry.resolveFontFamily(
      branding: ctx.branding,
      logicalName: style?.fontFamily ?? ctx.manifest.theme?.fontFamily,
      weight: style?.fontWeight ?? defaultWeight
    ) {
      return .custom(family, size: size).weight(weight)
    }
    return .system(size: size, weight: weight)
  }

  var body: some View {
    let fill = resolveColor(
      layer.fillColor,
      theme: ctx.manifest.theme,
      mode: ctx.theme,
      fallback: ctx.manifest.theme?.primary ?? .raw(ctx.theme == .dark ? "#fafafa" : "#0a0a0a")
    )
    let labelFont = textFont(layer.labelStyle, defaultSize: 11, defaultWeight: nil)
    let valueFont = textFont(layer.valueStyle, defaultSize: 14, defaultWeight: 600)
    VStack(spacing: 8) {
      ForEach(layer.children ?? [], id: \.id) { child in
        renderChild(child, ctx: ctx)
      }
      if showEndLabels {
        HStack {
          Text(layer.minLabel?.resolve(locale: ctx.locale) ?? "\(Int(layer.min))")
            .font(labelFont)
            .foregroundStyle(textColor(layer.labelStyle, fallback: .raw(ctx.theme == .dark ? "#a1a1aa" : "#52525b")))
            .opacity(layer.labelStyle?.opacity ?? 0.75)
          Spacer()
          Text(layer.maxLabel?.resolve(locale: ctx.locale) ?? "\(Int(layer.max))")
            .font(labelFont)
            .foregroundStyle(textColor(layer.labelStyle, fallback: .raw(ctx.theme == .dark ? "#a1a1aa" : "#52525b")))
            .opacity(layer.labelStyle?.opacity ?? 0.75)
        }
      }
      Slider(value: value, in: layer.min...layer.max, step: layer.step ?? 1)
        .tint(fill)
        .disabled(!ctx.interactive)
      if showSelectedValue {
        Text("\(Int(value.wrappedValue))")
          .font(valueFont)
          .foregroundStyle(textColor(layer.valueStyle, fallback: .raw(ctx.theme == .dark ? "#fafafa" : "#0a0a0a")))
          .opacity(layer.valueStyle?.opacity ?? 1)
          .frame(maxWidth: .infinity, alignment: .center)
      }
    }
    .rheoCommonStyle(layer.style, ctx: ctx, containerWidth: CGFloat(ctx.previewWidthPx))
  }
}
