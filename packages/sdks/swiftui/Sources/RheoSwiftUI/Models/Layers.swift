import Foundation

public enum LayerKind: String, Codable, Sendable {
  case stack
  case text
  case hyperlink
  case image
  case lottie
  case video
  case icon
  case button
  case backButton = "back_button"
  case progress
  case loader
  case counter
  case checkbox
  case singleChoice = "single_choice"
  case multipleChoice = "multiple_choice"
  case textInput = "text_input"
  case scaleInput = "scale_input"
  case oauthProvider = "oauth_provider"
  case oauthLogin = "oauth_login"
  case emailPasswordAuth = "email_password_auth"
  case emailPasswordField = "email_password_field"
  case emailPasswordSubmit = "email_password_submit"
  case carousel
}

public enum Layer: Codable, Equatable, Sendable, Identifiable {
  case stack(StackLayer)
  case text(TextLayer)
  case hyperlink(HyperlinkLayer)
  case image(ImageLayer)
  case lottie(LottieLayer)
  case video(VideoLayer)
  case icon(IconLayer)
  case button(ButtonLayer)
  case backButton(BackButtonLayer)
  case progress(ProgressLayer)
  case loader(LoaderLayer)
  case counter(CounterLayer)
  case checkbox(CheckboxLayer)
  case singleChoice(SingleChoiceLayer)
  case multipleChoice(MultipleChoiceLayer)
  case textInput(TextInputLayer)
  case scaleInput(ScaleInputLayer)
  case oauthProvider(OAuthProviderLayer)
  case oauthLogin(OAuthLoginLayer)
  case emailPasswordAuth(EmailPasswordAuthLayer)
  case emailPasswordField(EmailPasswordFieldLayer)
  case emailPasswordSubmit(EmailPasswordSubmitLayer)
  case carousel(CarouselLayer)

  private enum CodingKeys: String, CodingKey {
    case kind
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let kind = try container.decode(LayerKind.self, forKey: .kind)
    switch kind {
    case .stack: self = .stack(try StackLayer(from: decoder))
    case .text: self = .text(try TextLayer(from: decoder))
    case .hyperlink: self = .hyperlink(try HyperlinkLayer(from: decoder))
    case .image: self = .image(try ImageLayer(from: decoder))
    case .lottie: self = .lottie(try LottieLayer(from: decoder))
    case .video: self = .video(try VideoLayer(from: decoder))
    case .icon: self = .icon(try IconLayer(from: decoder))
    case .button: self = .button(try ButtonLayer(from: decoder))
    case .backButton: self = .backButton(try BackButtonLayer(from: decoder))
    case .progress: self = .progress(try ProgressLayer(from: decoder))
    case .loader: self = .loader(try LoaderLayer(from: decoder))
    case .counter: self = .counter(try CounterLayer(from: decoder))
    case .checkbox: self = .checkbox(try CheckboxLayer(from: decoder))
    case .singleChoice: self = .singleChoice(try SingleChoiceLayer(from: decoder))
    case .multipleChoice: self = .multipleChoice(try MultipleChoiceLayer(from: decoder))
    case .textInput: self = .textInput(try TextInputLayer(from: decoder))
    case .scaleInput: self = .scaleInput(try ScaleInputLayer(from: decoder))
    case .oauthProvider: self = .oauthProvider(try OAuthProviderLayer(from: decoder))
    case .oauthLogin: self = .oauthLogin(try OAuthLoginLayer(from: decoder))
    case .emailPasswordAuth: self = .emailPasswordAuth(try EmailPasswordAuthLayer(from: decoder))
    case .emailPasswordField: self = .emailPasswordField(try EmailPasswordFieldLayer(from: decoder))
    case .emailPasswordSubmit: self = .emailPasswordSubmit(try EmailPasswordSubmitLayer(from: decoder))
    case .carousel: self = .carousel(try CarouselLayer(from: decoder))
    }
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .stack(let layer): try layer.encode(to: encoder)
    case .text(let layer): try layer.encode(to: encoder)
    case .hyperlink(let layer): try layer.encode(to: encoder)
    case .image(let layer): try layer.encode(to: encoder)
    case .lottie(let layer): try layer.encode(to: encoder)
    case .video(let layer): try layer.encode(to: encoder)
    case .icon(let layer): try layer.encode(to: encoder)
    case .button(let layer): try layer.encode(to: encoder)
    case .backButton(let layer): try layer.encode(to: encoder)
    case .progress(let layer): try layer.encode(to: encoder)
    case .loader(let layer): try layer.encode(to: encoder)
    case .counter(let layer): try layer.encode(to: encoder)
    case .checkbox(let layer): try layer.encode(to: encoder)
    case .singleChoice(let layer): try layer.encode(to: encoder)
    case .multipleChoice(let layer): try layer.encode(to: encoder)
    case .textInput(let layer): try layer.encode(to: encoder)
    case .scaleInput(let layer): try layer.encode(to: encoder)
    case .oauthProvider(let layer): try layer.encode(to: encoder)
    case .oauthLogin(let layer): try layer.encode(to: encoder)
    case .emailPasswordAuth(let layer): try layer.encode(to: encoder)
    case .emailPasswordField(let layer): try layer.encode(to: encoder)
    case .emailPasswordSubmit(let layer): try layer.encode(to: encoder)
    case .carousel(let layer): try layer.encode(to: encoder)
    }
  }

  public var id: String {
    switch self {
    case .stack(let layer): return layer.id
    case .text(let layer): return layer.id
    case .hyperlink(let layer): return layer.id
    case .image(let layer): return layer.id
    case .lottie(let layer): return layer.id
    case .video(let layer): return layer.id
    case .icon(let layer): return layer.id
    case .button(let layer): return layer.id
    case .backButton(let layer): return layer.id
    case .progress(let layer): return layer.id
    case .loader(let layer): return layer.id
    case .counter(let layer): return layer.id
    case .checkbox(let layer): return layer.id
    case .singleChoice(let layer): return layer.id
    case .multipleChoice(let layer): return layer.id
    case .textInput(let layer): return layer.id
    case .scaleInput(let layer): return layer.id
    case .oauthProvider(let layer): return layer.id
    case .oauthLogin(let layer): return layer.id
    case .emailPasswordAuth(let layer): return layer.id
    case .emailPasswordField(let layer): return layer.id
    case .emailPasswordSubmit(let layer): return layer.id
    case .carousel(let layer): return layer.id
    }
  }

  public var kind: LayerKind {
    switch self {
    case .stack: return .stack
    case .text: return .text
    case .hyperlink: return .hyperlink
    case .image: return .image
    case .lottie: return .lottie
    case .video: return .video
    case .icon: return .icon
    case .button: return .button
    case .backButton: return .backButton
    case .progress: return .progress
    case .loader: return .loader
    case .counter: return .counter
    case .checkbox: return .checkbox
    case .singleChoice: return .singleChoice
    case .multipleChoice: return .multipleChoice
    case .textInput: return .textInput
    case .scaleInput: return .scaleInput
    case .oauthProvider: return .oauthProvider
    case .oauthLogin: return .oauthLogin
    case .emailPasswordAuth: return .emailPasswordAuth
    case .emailPasswordField: return .emailPasswordField
    case .emailPasswordSubmit: return .emailPasswordSubmit
    case .carousel: return .carousel
    }
  }

  public var children: [Layer] {
    switch self {
    case .stack(let layer): return layer.children
    case .hyperlink(let layer): return layer.children
    case .button(let layer): return layer.children
    case .backButton(let layer): return layer.children
    case .singleChoice(let layer): return layer.children
    case .multipleChoice(let layer): return layer.children
    case .textInput(let layer): return layer.children ?? []
    case .scaleInput(let layer): return layer.children ?? []
    case .oauthProvider(let layer): return layer.children ?? []
    case .oauthLogin(let layer): return layer.children.map { .oauthProvider($0) }
    case .emailPasswordAuth(let layer): return layer.children.map(\.asLayer)
    case .emailPasswordField(let layer): return layer.children ?? []
    case .emailPasswordSubmit(let layer): return layer.children
    case .carousel(let layer): return layer.slides.map { .stack($0) }
    default: return []
    }
  }
}

public protocol BaseLayer {
  var id: String { get }
  var name: String? { get }
}

public struct StackLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var style: CommonStyle?
  public var styleBreakpoints: CommonStyleBreakpoints?
  public var stackLayoutBreakpoints: StackLayoutBreakpoints?
  public var selectedStyle: CommonStyle?
  public var direction: String
  public var gap: Double?
  public var align: String?
  public var justify: String?
  public var distribution: String?
  public var wrap: Bool?
  public var restingMotions: [RestingMotion]?
  public var children: [Layer]
}

public struct TextLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var text: LocalizedText
  public var style: TextStyle?
  public var styleBreakpoints: TextStyleBreakpoints?
  public var restingMotions: [RestingMotion]?
}

public struct HyperlinkLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var href: String
  public var children: [Layer]
  public var direction: String?
  public var gap: Double?
  public var align: String?
  public var distribution: String?
  public var wrap: Bool?
  public var style: CommonStyle?
  public var styleBreakpoints: CommonStyleBreakpoints?
  public var restingMotions: [RestingMotion]?
}

public struct MediaReference: Codable, Equatable, Sendable {
  public var mediaAssetId: String
}

public struct ImageLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var media: MediaReference?
  public var alt: String?
  public var style: ImageStyle?
  public var styleBreakpoints: ImageStyleBreakpoints?
  public var restingMotions: [RestingMotion]?
}

public struct LottieLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var media: MediaReference?
  public var loop: Bool?
  public var autoPlay: Bool?
  public var triggerLayerId: String?
  public var onComplete: LoaderOnComplete?
  public var style: ImageStyle?
  public var styleBreakpoints: ImageStyleBreakpoints?
  public var restingMotions: [RestingMotion]?
}

public struct VideoLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var media: MediaReference?
  public var loop: Bool?
  public var autoPlay: Bool?
  public var triggerLayerId: String?
  public var onComplete: LoaderOnComplete?
  public var audioEnabled: Bool?
  public var style: ImageStyle?
  public var styleBreakpoints: ImageStyleBreakpoints?
  public var restingMotions: [RestingMotion]?
}

public struct IconLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var family: String
  public var iconName: String
  public var style: IconStyle?
  public var styleBreakpoints: IconStyleBreakpoints?
  public var restingMotions: [RestingMotion]?
}

public enum ButtonAction: Codable, Equatable, Sendable {
  case none
  case `continue`
  case skip
  case endFlow
  case goBackOneScreen(fallbackScreenId: String?)
  case goToStep(screenId: String)
  case requestOSPermission(permissionKey: OSPermissionKey, outcomes: PermissionOutcomes)
  case requestAppReview
  case playMedia(targetLayerIds: [String])

  private enum CodingKeys: String, CodingKey {
    case kind
    case fallbackScreenId
    case screenId
    case permissionKey
    case outcomes
    case targetLayerIds
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let kind = try container.decode(String.self, forKey: .kind)
    switch kind {
    case "none": self = .none
    case "continue": self = .continue
    case "skip": self = .skip
    case "end_flow": self = .endFlow
    case "go_back_one_screen": self = .goBackOneScreen(fallbackScreenId: try container.decodeIfPresent(String.self, forKey: .fallbackScreenId))
    case "go_to_step": self = .goToStep(screenId: try container.decode(String.self, forKey: .screenId))
    case "request_os_permission":
      self = .requestOSPermission(
        permissionKey: try container.decode(OSPermissionKey.self, forKey: .permissionKey),
        outcomes: try container.decode(PermissionOutcomes.self, forKey: .outcomes)
      )
    case "request_app_review":
      self = .requestAppReview
    case "play_media":
      self = .playMedia(targetLayerIds: try container.decode([String].self, forKey: .targetLayerIds))
    default:
      throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unknown button action \(kind)")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .none:
      try container.encode("none", forKey: .kind)
    case .continue:
      try container.encode("continue", forKey: .kind)
    case .skip:
      try container.encode("skip", forKey: .kind)
    case .endFlow:
      try container.encode("end_flow", forKey: .kind)
    case .goBackOneScreen(let fallback):
      try container.encode("go_back_one_screen", forKey: .kind)
      try container.encodeIfPresent(fallback, forKey: .fallbackScreenId)
    case .goToStep(let screenId):
      try container.encode("go_to_step", forKey: .kind)
      try container.encode(screenId, forKey: .screenId)
    case .requestOSPermission(let permissionKey, let outcomes):
      try container.encode("request_os_permission", forKey: .kind)
      try container.encode(permissionKey, forKey: .permissionKey)
      try container.encode(outcomes, forKey: .outcomes)
    case .requestAppReview:
      try container.encode("request_app_review", forKey: .kind)
    case .playMedia(let targetLayerIds):
      try container.encode("play_media", forKey: .kind)
      try container.encode(targetLayerIds, forKey: .targetLayerIds)
    }
  }
}

public enum AppReviewOutcome: String, Codable, Equatable, Sendable {
  case notShown = "not_shown"
  case dismissed = "dismissed"
}

public typealias OSPermissionKey = String

public enum PermissionOutcome: String, Codable, Equatable, Sendable {
  case granted
  case denied
  case blocked
}

public struct PermissionOutcomes: Codable, Equatable, Sendable {
  public var granted: String
  public var denied: String
  public var blocked: String
}

public struct ButtonLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var children: [Layer]
  public var action: ButtonAction
  public var variant: String
  public var direction: String?
  public var gap: Double?
  public var align: String?
  public var distribution: String?
  public var style: ButtonStyle?
  public var styleBreakpoints: ButtonStyleBreakpoints?
  public var buttonLayoutBreakpoints: ButtonLayoutBreakpoints?
  public var restingMotions: [RestingMotion]?
}

public struct BackButtonLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var children: [Layer]
  public var variant: String
  public var direction: String?
  public var gap: Double?
  public var align: String?
  public var distribution: String?
  public var style: ButtonStyle?
  public var styleBreakpoints: ButtonStyleBreakpoints?
  public var buttonLayoutBreakpoints: ButtonLayoutBreakpoints?
  public var fallbackScreenId: String?
  public var restingMotions: [RestingMotion]?
}

public struct ProgressLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var trackColor: ThemedColor?
  public var fillColor: ThemedColor?
  public var style: CommonStyle?
  public var restingMotions: [RestingMotion]?
}

public struct LoaderOnComplete: Codable, Equatable, Sendable {
  public var mode: String
  public var screenId: String?
}

public struct LoaderLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var variant: String?
  public var targetPercent: Double?
  public var fillDelayMs: Int?
  public var durationMs: Int?
  public var onComplete: LoaderOnComplete?
  public var trackColor: ThemedColor?
  public var trackOpacity: Double?
  public var fillColor: ThemedColor?
  public var align: String?
  public var style: CommonStyle?
  public var restingMotions: [RestingMotion]?
}

public struct CounterLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var startValue: Double
  public var endValue: Double
  public var durationMs: Int?
  public var delayMs: Int?
  public var decimalPlaces: Int?
  public var displayKind: String?
  public var timeFormat: String?
  public var style: TextStyle?
  public var styleBreakpoints: TextStyleBreakpoints?
  public var restingMotions: [RestingMotion]?
}

public struct CheckboxGlyphStyle: Codable, Equatable, Sendable {
  public var sizePx: Double?
  public var radiusPx: Double?
  public var background: ThemedColor?
  public var border: Border?
  public var checkColor: ThemedColor?
  public var opacity: Double?
  public var shadow: DropShadow?
}

public struct CheckboxLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var fieldKey: String
  public var blocking: Bool?
  public var uncheckedStyle: CheckboxGlyphStyle?
  public var checkedStyle: CheckboxGlyphStyle?
  public var style: CommonStyle?
  public var styleBreakpoints: CommonStyleBreakpoints?
  public var restingMotions: [RestingMotion]?
}

public struct ChoiceOptionBinding: Codable, Equatable, Sendable {
  public var optionId: String
  public var rootLayerId: String
}

public struct ChoiceBranchCondition: Codable, Equatable, Sendable {
  public var choiceId: String
  public var goTo: String?
}

public struct ChoiceBranching: Codable, Equatable, Sendable {
  public var enabled: Bool
  public var conditions: [ChoiceBranchCondition]
}

public struct SingleChoiceLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var fieldKey: String
  public var children: [Layer]
  public var optionBindings: [ChoiceOptionBinding]
  public var branching: ChoiceBranching
  public var direction: String?
  public var gap: Double?
  public var columns: Int?
  public var style: CommonStyle?
  public var styleBreakpoints: CommonStyleBreakpoints?
  public var restingMotions: [RestingMotion]?
}

public struct MultipleChoiceLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var fieldKey: String
  public var children: [Layer]
  public var optionBindings: [ChoiceOptionBinding]
  public var minSelections: Int?
  public var maxSelections: Int?
  public var branching: ChoiceBranching
  public var direction: String?
  public var gap: Double?
  public var columns: Int?
  public var style: CommonStyle?
  public var styleBreakpoints: CommonStyleBreakpoints?
  public var restingMotions: [RestingMotion]?
}

public struct TextInputLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var fieldKey: String
  public var placeholder: LocalizedText?
  public var inputType: String?
  public var required: Bool?
  public var minLength: Int?
  public var maxLength: Int?
  public var classification: String
  public var children: [Layer]?
  public var style: CommonStyle?
  public var restingMotions: [RestingMotion]?
}

public struct ScaleInputLabelStyle: Codable, Equatable, Sendable {
  public var fontFamily: String?
  public var fontSize: Double?
  public var fontWeight: Int?
  public var color: ThemedColor?
  public var align: String?
  public var lineHeight: Double?
  public var opacity: Double?
}

public struct ScaleInputLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var fieldKey: String
  public var min: Double
  public var max: Double
  public var step: Double?
  public var defaultValue: Double?
  public var minLabel: LocalizedText?
  public var maxLabel: LocalizedText?
  public var labelStyle: ScaleInputLabelStyle?
  public var valueStyle: ScaleInputLabelStyle?
  public var showLabels: Bool?
  public var showValue: Bool?
  public var trackHeight: Double?
  public var trackColor: ThemedColor?
  public var fillColor: ThemedColor?
  public var thumbSize: Double?
  public var thumbColor: ThemedColor?
  public var children: [Layer]?
  public var style: CommonStyle?
  public var restingMotions: [RestingMotion]?
}

public struct OAuthProvider: Codable, Equatable, Sendable {
  public var type: String
  public var provider: String?
  public var rowId: String?
  public var label: LocalizedText?
  public var family: String?
  public var iconName: String?
}

public struct OAuthProviderLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var variant: String
  public var provider: String?
  public var rowId: String?
  public var label: LocalizedText?
  public var family: String?
  public var iconName: String?
  public var buttonVariant: String?
  public var direction: String?
  public var gap: Double?
  public var align: String?
  public var distribution: String?
  public var children: [Layer]?
  public var style: ButtonStyle?
  public var styleBreakpoints: ButtonStyleBreakpoints?
  public var buttonLayoutBreakpoints: ButtonLayoutBreakpoints?
}

extension OAuthProviderLayer {
  public var manifestProvider: OAuthProvider {
    if variant == "preset" {
      return OAuthProvider(type: "preset", provider: provider, rowId: nil, label: nil, family: nil, iconName: nil)
    }
    return OAuthProvider(type: "custom", provider: nil, rowId: rowId, label: label, family: family, iconName: iconName)
  }
}

public struct OAuthLoginLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var children: [OAuthProviderLayer]
  public var gap: Double?
  public var align: String?
  public var style: CommonStyle?
  public var styleBreakpoints: CommonStyleBreakpoints?
  public var restingMotions: [RestingMotion]?
}

public enum EmailPasswordAuthMode: String, Codable, Equatable, Sendable {
  case signIn = "sign_in"
  case signUp = "sign_up"
}

public typealias EmailPasswordSlot = String

public enum EmailPasswordAuthChild: Codable, Equatable, Sendable, Identifiable {
  case field(EmailPasswordFieldLayer)
  case submit(EmailPasswordSubmitLayer)

  private enum CodingKeys: String, CodingKey {
    case kind
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let kind = try container.decode(String.self, forKey: .kind)
    switch kind {
    case "email_password_field":
      self = .field(try EmailPasswordFieldLayer(from: decoder))
    case "email_password_submit":
      self = .submit(try EmailPasswordSubmitLayer(from: decoder))
    default:
      throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unexpected email/password child \(kind)")
    }
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .field(let layer): try layer.encode(to: encoder)
    case .submit(let layer): try layer.encode(to: encoder)
    }
  }

  public var id: String {
    switch self {
    case .field(let layer): return layer.id
    case .submit(let layer): return layer.id
    }
  }

  public var asLayer: Layer {
    switch self {
    case .field(let layer): return .emailPasswordField(layer)
    case .submit(let layer): return .emailPasswordSubmit(layer)
    }
  }
}

public struct EmailPasswordAuthLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var mode: EmailPasswordAuthMode
  public var fieldKey: String
  public var minPasswordLength: Int?
  public var children: [EmailPasswordAuthChild]
  public var gap: Double?
  public var align: String?
  public var style: CommonStyle?
  public var styleBreakpoints: CommonStyleBreakpoints?
  public var restingMotions: [RestingMotion]?
}

public struct EmailPasswordFieldLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var slot: EmailPasswordSlot
  public var placeholder: LocalizedText?
  public var children: [Layer]?
  public var style: CommonStyle?
  public var styleBreakpoints: CommonStyleBreakpoints?
}

public struct EmailPasswordSubmitLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var buttonVariant: String
  public var direction: String?
  public var gap: Double?
  public var align: String?
  public var distribution: String?
  public var children: [Layer]
  public var style: ButtonStyle?
  public var styleBreakpoints: ButtonStyleBreakpoints?
  public var buttonLayoutBreakpoints: ButtonLayoutBreakpoints?
}

public struct CarouselIndicatorsStyle: Codable, Equatable, Sendable {
  public var width: Double?
  public var height: Double?
  public var defaultColor: ThemedColor?
  public var defaultOpacity: Double?
  public var activeColor: ThemedColor?
  public var activeOpacity: Double?
  public var activeWidth: Double?
  public var activeHeight: Double?
  public var border: Border?
  public var activeBorder: Border?
}

public struct CarouselPageControl: Codable, Equatable, Sendable {
  public var position: String
  public var spacing: Double?
  public var padding: Padding?
  public var margin: Padding?
  public var indicators: CarouselIndicatorsStyle?
  public var border: Border?
  public var shadow: DropShadow?
}

public struct CarouselLayer: Codable, Equatable, Sendable, BaseLayer, Identifiable {
  public var id: String
  public var name: String?
  public var kind: String
  public var slides: [StackLayer]
  public var pageAlignment: String?
  public var pageSpacing: Double?
  public var pagePeek: Double?
  public var openOn: Int?
  public var loop: Bool?
  public var autoAdvance: Bool?
  public var autoAdvanceMs: Int?
  public var pageControl: CarouselPageControl?
  public var style: CommonStyle?
  public var restingMotions: [RestingMotion]?
}

public struct RestingMotion: Codable, Equatable, Sendable, Identifiable {
  public var id: String
  public var preset: String
  public var durationMs: Int?
  public var cycleDurationMs: Int?
  public var loop: Bool?
  public var intensity: Double?
  public var bounceAmplitudePx: Double?
  public var scaleDirection: String?
  public var scalePercent: Double?
  public var scalePatternDurationMs: Int?
  public var scaleSpringBack: Bool?
  public var scaleUpPercent: Double?
  public var scaleDownPercent: Double?
  public var translateRangePx: Double?
  public var translatePeakXPx: Double?
  public var translatePeakYPx: Double?
  public var translatePeakXPercent: Double?
  public var translatePeakYPercent: Double?
  public var translateSpringBack: Bool?
  public var rotateMaxDeg: Double?
  public var rotateDirection: String?
  public var rotateSpringBack: Bool?
  public var pulseMinOpacity: Double?
  public var delayMsAfterMountEnd: Int?
  public var timelineStartMs: Int?
}
