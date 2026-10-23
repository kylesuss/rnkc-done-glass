//
//  KeyboardExtenderContainerView.swift
//  Pods
//
//  Created by Kiryl Ziusko on 11/07/2025.
//

import UIKit

// Repro only: 1.22.8's file with the proposed `glass` prop (proposal/keyboard-extender-glass-prop.patch),
// class renamed so it can build next to the unmodified copy in vendor/rnkc-1.22.8.
@objc
public class PatchedKeyboardExtenderContainerView: NSObject {
  private static func usesModernKeyboard() -> Bool {
    #if canImport(UIKit.UIGlassEffect)
      if #available(iOS 26.0, *) {
        let requiresCompat = Bundle.main.object(forInfoDictionaryKey: "UIDesignRequiresCompatibility") as? Bool ?? false
        return !requiresCompat
      }
    #endif
    return false
  }

  @objc public static func keyboardBorderRadius() -> CGFloat {
    return usesModernKeyboard() ? 30 : 0
  }

  @objc public static func create(frame: CGRect, contentView: UIView, glass: Bool) -> UIView {
    if usesModernKeyboard() {
      if #available(iOS 26.0, *) {
        return ModernContainerView(frame: frame, contentView: contentView, glass: glass)
      }
    }
    return LegacyContainerView(frame: frame, contentView: contentView)
  }
}

private class BaseContainerView: UIInputView {
  var contentView: UIView!

  init(frame: CGRect, contentView: UIView) {
    super.init(frame: frame, inputViewStyle: .keyboard)
    self.contentView = contentView
    commonSetup()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func commonSetup() {
    allowsSelfSizing = true
    autoresizingMask = [.flexibleHeight]
    setupContainerSpecifics()
  }

  func setupContainerSpecifics() {
    updateContentFrame(desiredHeight: calculateDesiredHeight())
  }

  func calculateDesiredHeight() -> CGFloat {
    guard let firstSubview = contentView.subviews.first else { return 0 }
    return firstSubview.frame.height
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    let desiredHeight = calculateDesiredHeight()

    if abs(frame.height - desiredHeight) > 0.001 {
      frame.size.height = desiredHeight

      updateContentFrame(desiredHeight: desiredHeight)

      // Trigger layout updates
      invalidateIntrinsicContentSize()
      setNeedsLayout()
      UIResponder.current?.reloadInputViews()
    }
  }

  func updateContentFrame(desiredHeight _: CGFloat) {
    // Override in subclasses
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: frame.height)
  }
}

// MARK: - Modern Implementation (iOS 26.0+)

@available(iOS 26.0, *)
private class ModernContainerView: BaseContainerView {
  private let paddingHorizontal: CGFloat = 20.0
  private let paddingBottom: CGFloat = 10.0
  private let glass: Bool
  /// The glass capsule, or with `glass: false` a plain view in the same frame.
  private var floatingView: UIView?

  init(frame: CGRect, contentView: UIView, glass: Bool) {
    self.glass = glass
    super.init(frame: frame, contentView: contentView)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func setupContainerSpecifics() {
    setupVisualEffect()
    super.setupContainerSpecifics()
  }

  private func setupVisualEffect() {
    guard glass else {
      let plainView = UIView()
      plainView.addSubview(contentView)
      addSubview(plainView)
      floatingView = plainView
      return
    }

    #if canImport(UIKit.UIGlassEffect)
      let isDark = FocusedInputHolder.shared.get()?.keyboardAppearanceValue == "dark"
      let glassEffect = UIGlassEffect()
      let color =
        isDark ? UIColor.black.withAlphaComponent(0.3) : UIColor.gray.withAlphaComponent(0.3)
      glassEffect.tintColor = color
      glassEffect.isInteractive = true

      let visualEffectView = UIVisualEffectView(effect: glassEffect)
      visualEffectView.overrideUserInterfaceStyle = isDark ? .dark : .light
      visualEffectView.cornerConfiguration = .capsule()
      visualEffectView.contentView.addSubview(contentView)
      addSubview(visualEffectView)
      floatingView = visualEffectView
    #endif
  }

  override func updateContentFrame(desiredHeight: CGFloat) {
    floatingView?.frame = CGRect(
      x: paddingHorizontal,
      y: -paddingBottom,
      width: bounds.width - 2 * paddingHorizontal,
      height: desiredHeight
    )
    contentView.frame = CGRect(
      x: -paddingHorizontal,
      y: 0,
      width: bounds.width,
      height: desiredHeight
    )
  }
}

// MARK: - Legacy Implementation (Pre-iOS 26.0)

private class LegacyContainerView: BaseContainerView {
  override func setupContainerSpecifics() {
    addSubview(contentView)
    super.setupContainerSpecifics()
  }

  override func updateContentFrame(desiredHeight _: CGFloat) {
    contentView.frame = bounds
  }
}
