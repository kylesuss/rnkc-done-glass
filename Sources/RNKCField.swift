import SwiftUI
import UIKit

enum RNKCVariant: String {
  /// Stock 1.22.8 container, content = a tinted glass "Done" pill (what JS renders via LiquidGlassView).
  case stockTintedPill
  /// Stock 1.22.8 container, content = a plain "Done" text button (closest the stock library gets).
  case stockText
  /// Patched container with `glass: false`, same tinted pill content as `stockTintedPill`.
  case patchedTintedPill
}

/// A decimal-pad field whose accessory is built the way RNKC's `KeyboardExtender` builds it:
/// `KeyboardExtenderManager.mm` keeps a `_contentView` whose first subview is the JS root
/// (`<View style={{ width }}>{children}</View>`), and hands it to
/// `KeyboardExtenderContainerView.create(frame:contentView:)` sized to that subview's height.
struct RNKCField: UIViewRepresentable {
  let variant: RNKCVariant
  var testID: String? = nil

  private static let barHeight: CGFloat = 40  // the pill alone; the container supplies the 10pt float

  final class Coordinator {
    var container: UIView?
    var observer: NSObjectProtocol?
    deinit { observer.map(NotificationCenter.default.removeObserver) }
  }

  func makeCoordinator() -> Coordinator { Coordinator() }

  func makeUIView(context: Context) -> UITextField {
    let field = UITextField()
    field.placeholder = "0.00"
    field.keyboardType = .decimalPad
    field.textAlignment = .right
    field.accessibilityIdentifier = testID ?? variant.rawValue

    // Like `KeyboardExtenderManager.mm`: attach on `textDidBeginEditing`, build the container once
    // on first attach, then `reloadInputViews` — so the bar arrives after the keyboard starts.
    let coordinator = context.coordinator
    coordinator.observer = NotificationCenter.default.addObserver(
      forName: UITextField.textDidBeginEditingNotification, object: field, queue: .main
    ) { _ in
      FocusedInputHolder.shared.set(field)
      if coordinator.container == nil {
        coordinator.container = Self.makeContainer(variant: variant, field: field)
      }
      field.inputAccessoryView = coordinator.container
      field.reloadInputViews()
    }
    return field
  }

  func updateUIView(_ uiView: UITextField, context: Context) {}

  private static func makeContainer(variant: RNKCVariant, field: UITextField) -> UIView {
    let width = UIScreen.main.bounds.width
    let contentView = UIView(frame: .zero)
    let jsRoot = UIView(frame: CGRect(x: 0, y: 0, width: width, height: Self.barHeight))
    contentView.addSubview(jsRoot)

    let dismiss = UIAction { _ in field.resignFirstResponder() }
    switch variant {
    case .stockTintedPill, .patchedTintedPill:
      jsRoot.addSubview(Self.tintedPill(width: width, action: dismiss))
    case .stockText:
      jsRoot.addSubview(Self.textButton(width: width, action: dismiss))
    }

    let frame = CGRect(x: 0, y: 0, width: width, height: Self.barHeight)
    switch variant {
    case .stockTintedPill, .stockText:
      return KeyboardExtenderContainerView.create(frame: frame, contentView: contentView)
    case .patchedTintedPill:
      return PatchedKeyboardExtenderContainerView.create(
        frame: frame, contentView: contentView, glass: false)
    }
  }

  /// What `@callstack/liquid-glass`'s `LiquidGlassView` renders: a `UIGlassEffect` view, tinted,
  /// interactive, capsule-cornered, at the trailing edge with 8pt inset.
  private static func tintedPill(width: CGFloat, action: UIAction) -> UIView {
    let effect = UIGlassEffect()
    effect.tintColor = .tintColor
    effect.isInteractive = true
    let glass = UIVisualEffectView(effect: effect)
    glass.cornerConfiguration = .capsule()
    glass.frame = CGRect(x: width - 8 - 66, y: 0, width: 66, height: 40)

    var config = UIButton.Configuration.plain()
    config.title = "Done"
    config.baseForegroundColor = .white
    let button = UIButton(configuration: config, primaryAction: action)
    button.frame = glass.bounds
    glass.contentView.addSubview(button)
    return glass
  }

  private static func textButton(width: CGFloat, action: UIAction) -> UIView {
    var config = UIButton.Configuration.plain()
    config.title = "Done"
    let button = UIButton(configuration: config, primaryAction: action)
    button.frame = CGRect(x: width - 16 - 66, y: 0, width: 66, height: 40)
    return button
  }
}
