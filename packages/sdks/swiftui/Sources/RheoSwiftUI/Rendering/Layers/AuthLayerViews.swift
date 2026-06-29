import SwiftUI

struct OAuthLoginView: View {
  var layer: OAuthLoginLayer
  var ctx: LayerRendererContext
  @State private var pendingKey: String?

  var body: some View {
    let resolvedOuter = resolveCommonStyleAtWidth(layer.style, layer.styleBreakpoints, width: ctx.previewWidthPx)
    let inner = stripCommonLayoutForInner(resolvedOuter)
    let gap = CGFloat(layer.gap ?? LayoutScalarDefaults.authGap)
    let stretch = layer.align == "stretch"

    VStack(alignment: horizontalAlignment(layer.align), spacing: gap) {
      ForEach(layer.children, id: \.id) { provider in
        let rowKey = provider.id
        let disabled = !ctx.interactive || pendingKey != nil
        let busy = pendingKey == rowKey

        if provider.variant == "preset", let preset = oauthLoginPreset(from: provider.provider) {
          presetRow(provider: provider, preset: preset, rowKey: rowKey, stretch: stretch, disabled: disabled, busy: busy)
        } else {
          customRow(provider: provider, rowKey: rowKey, stretch: stretch, disabled: disabled, busy: busy)
        }
      }
    }
    .frame(maxWidth: stretch ? .infinity : nil, alignment: .leading)
    .rheoCommonStyle(inner, ctx: ctx, containerWidth: CGFloat(ctx.previewWidthPx))
  }

  @ViewBuilder
  private func presetRow(
    provider: OAuthProviderLayer,
    preset: OAuthLoginPreset,
    rowKey: String,
    stretch: Bool,
    disabled: Bool,
    busy: Bool
  ) -> some View {
    let resolvedChrome = resolveCommonStyleAtWidth(
      provider.style?.asCommonStyle,
      provider.styleBreakpoints?.mapValues(\.asCommonStyle),
      width: ctx.previewWidthPx
    )
    let brand = oauthPresetBrandModel(preset, mode: ctx.theme)
    let label = oauthPresetEffectiveLabel(provider: preset, label: provider.label, locale: ctx.locale)
    let labelColor = Color.rheo(brand.labelColor)
    let iconColor = Color.rheo(brand.iconColor)
    let rowWidth = stretch
      ? widthPoints(resolvedChrome?.width, containerWidth: CGFloat(ctx.previewWidthPx)) ?? CGFloat.infinity
      : widthPoints(resolvedChrome?.width, containerWidth: CGFloat(ctx.previewWidthPx))

    Button {
      fireOAuth(provider: provider, rowKey: rowKey)
    } label: {
      HStack(spacing: 10) {
        if busy {
          ProgressView()
            .tint(iconColor)
        } else {
          OAuthPresetGlyph(preset: preset, color: iconColor, size: 22)
        }
        Text(label)
          .font(.system(size: brand.fontSize, weight: brand.fontWeight))
          .foregroundStyle(labelColor)
          .multilineTextAlignment(.center)
          .lineLimit(2)
      }
      .frame(maxWidth: .infinity)
      .padding(.top, CGFloat(resolvedChrome?.padding?.t ?? 12))
      .padding(.trailing, CGFloat(resolvedChrome?.padding?.r ?? 16))
      .padding(.bottom, CGFloat(resolvedChrome?.padding?.b ?? 12))
      .padding(.leading, CGFloat(resolvedChrome?.padding?.l ?? 16))
      .background(Color.rheo(brand.backgroundColor))
      .overlay(
        RoundedRectangle(cornerRadius: CGFloat(resolvedChrome?.radius ?? 10))
          .stroke(Color.rheo(brand.borderColor), lineWidth: brand.borderWidth)
      )
      .clipShape(RoundedRectangle(cornerRadius: CGFloat(resolvedChrome?.radius ?? 10)))
    }
    .buttonStyle(.plain)
    .frame(maxWidth: rowWidth == CGFloat.infinity ? .infinity : nil)
    .frame(width: rowWidth == CGFloat.infinity ? nil : rowWidth)
    .opacity(disabled && ctx.interactive ? 0.5 : 1)
    .disabled(disabled)
  }

  @ViewBuilder
  private func customRow(
    provider: OAuthProviderLayer,
    rowKey: String,
    stretch: Bool,
    disabled: Bool,
    busy: Bool
  ) -> some View {
    let resolved = resolveButtonStyleAtWidth(provider.style, provider.styleBreakpoints, width: ctx.previewWidthPx)
    let palette = buttonPalette(provider.buttonVariant ?? "secondary", mode: ctx.theme)
    let isVertical = provider.direction == "vertical"
    let inner = stripCommonLayoutForInner(resolved?.asCommonStyle)

    Button {
      fireOAuth(provider: provider, rowKey: rowKey)
    } label: {
      Group {
        if busy {
          ProgressView()
            .tint(Color.rheo(palette.color))
        } else {
          if isVertical {
            VStack(alignment: horizontalAlignment(provider.align), spacing: CGFloat(provider.gap ?? LayoutScalarDefaults.oauthProviderGap)) {
              customChildren(provider: provider, palette: palette, buttonStyle: resolved)
            }
          } else {
            HStack(alignment: verticalAlignment(provider.align), spacing: CGFloat(provider.gap ?? LayoutScalarDefaults.oauthProviderGap)) {
              customChildren(provider: provider, palette: palette, buttonStyle: resolved)
            }
          }
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, CGFloat(resolved?.padding?.t ?? 12))
      .padding(.horizontal, CGFloat(resolved?.padding?.l ?? 16))
      .rheoButtonChromeBackground(style: resolved, palette: palette, ctx: ctx)
      .clipShape(RoundedRectangle(cornerRadius: CGFloat(resolved?.radius ?? 10)))
      .overlay(
        RoundedRectangle(cornerRadius: CGFloat(resolved?.radius ?? 10))
          .stroke(Color.rheo(palette.border), lineWidth: palette.border == "transparent" ? 0 : 1)
      )
    }
    .buttonStyle(.plain)
    .frame(maxWidth: stretch ? .infinity : nil)
    .rheoCommonStyle(inner, ctx: ctx, containerWidth: CGFloat(ctx.previewWidthPx))
    .opacity(disabled && ctx.interactive ? 0.5 : 1)
    .disabled(disabled)
  }

  @ViewBuilder
  private func customChildren(
    provider: OAuthProviderLayer,
    palette: ButtonPalette,
    buttonStyle: ButtonStyle?
  ) -> some View {
    ForEach(provider.children ?? [], id: \.id) { child in
      if case .text(let textLayer) = child {
        ButtonLabelText(textLayer: textLayer, buttonStyle: buttonStyle, palette: palette, ctx: ctx)
      } else {
        renderChild(child, ctx: ctx)
      }
    }
  }

  private func fireOAuth(provider: OAuthProviderLayer, rowKey: String) {
    guard ctx.interactive, pendingKey == nil else { return }
    pendingKey = rowKey
    let payload = OAuthLoginHandlerPayload(
      manifest: ctx.manifest,
      screenId: ctx.screen.id,
      layerId: layer.id,
      provider: provider.manifestProvider,
      resolve: { result in
        DispatchQueue.main.async {
          ctx.onRespond(
            .oauthLoginResolve(
              layerId: layer.id,
              provider: provider.manifestProvider,
              success: result.success,
              customerExternalId: result.customerExternalId,
              error: result.error
            )
          )
          pendingKey = nil
        }
      }
    )
    if let handler = ctx.oauthLoginHandler {
      handler(payload)
    } else {
      payload.resolve(.init(success: false))
    }
  }
}

struct EmailPasswordAuthView: View {
  var layer: EmailPasswordAuthLayer
  var ctx: LayerRendererContext
  @State private var email = ""
  @State private var password = ""
  @State private var confirm = ""
  @State private var error: String?
  @State private var pending = false

  var body: some View {
    VStack(alignment: horizontalAlignment(layer.align), spacing: CGFloat(layer.gap ?? LayoutScalarDefaults.authGap)) {
      ForEach(layer.children) { child in
        switch child {
        case .field(let field):
          fieldView(field)
        case .submit(let submit):
          submitView(submit)
        }
      }
      if let error {
        Text(error)
          .font(.caption)
          .foregroundStyle(.red)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .rheoCommonStyle(layer.style, ctx: ctx, containerWidth: CGFloat(ctx.previewWidthPx))
  }

  @ViewBuilder private func fieldView(_ field: EmailPasswordFieldLayer) -> some View {
    let placeholder = field.placeholder?.resolve(locale: ctx.locale) ?? field.slot.capitalized
    VStack(alignment: .leading, spacing: 6) {
      ForEach(field.children ?? [], id: \.id) { child in
        renderChild(child, ctx: ctx)
      }
      if field.slot == "password" || field.slot == "confirm" {
        SecureField(placeholder, text: binding(for: field.slot))
          .textFieldStyle(.roundedBorder)
      } else {
        TextField(placeholder, text: binding(for: field.slot))
          .textFieldStyle(.roundedBorder)
          .keyboardType(.emailAddress)
          .textInputAutocapitalization(.never)
      }
    }
  }

  private func submitView(_ submit: EmailPasswordSubmitLayer) -> some View {
    Button {
      fire()
    } label: {
      HStack {
        if pending {
          ProgressView()
        } else {
          ForEach(submit.children, id: \.id) { child in
            renderChild(child, ctx: ctx)
          }
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 12)
      .padding(.horizontal, 16)
      .background(resolveColor(nil, theme: ctx.manifest.theme, mode: ctx.theme, fallback: .raw(buttonPalette(submit.buttonVariant, mode: ctx.theme).background)))
      .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    .buttonStyle(.plain)
    .disabled(!ctx.interactive || pending)
  }

  private func binding(for slot: String) -> Binding<String> {
    Binding {
      if slot == "email" { return email }
      if slot == "confirm" { return confirm }
      return password
    } set: { next in
      error = nil
      if slot == "email" { email = next }
      else if slot == "confirm" { confirm = next }
      else { password = next }
    }
  }

  private func fire() {
    error = nil
    let validation = validateEmailPasswordAuthFields(
      mode: layer.mode,
      email: email,
      password: password,
      confirmPassword: confirm,
      minPasswordLength: layer.minPasswordLength ?? 8
    )
    if case .invalid(let message) = validation {
      error = message
      return
    }
    guard ctx.interactive else { return }
    pending = true
    let payload = EmailPasswordAuthHandlerPayload(
      manifest: ctx.manifest,
      screenId: ctx.screen.id,
      layerId: layer.id,
      fieldKey: layer.fieldKey,
      mode: layer.mode,
      email: email,
      password: password,
      confirmPassword: layer.mode == .signUp ? confirm : nil,
      resolve: { result in
        DispatchQueue.main.async {
          ctx.onRespond(.emailPasswordAuthResolve(layerId: layer.id, fieldKey: layer.fieldKey, mode: layer.mode, email: email, password: password, confirmPassword: layer.mode == .signUp ? confirm : nil, success: result.success, error: result.error))
          pending = false
        }
      }
    )
    if let handler = ctx.emailPasswordAuthHandler {
      handler(payload)
    } else {
      payload.resolve(.init(success: true))
    }
  }
}
