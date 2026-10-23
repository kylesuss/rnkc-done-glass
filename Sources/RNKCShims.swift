import UIKit

// The vendored container calls `UIResponder.current?.reloadInputViews()`. RNKC's own version walks
// the active window; this stand-in finds the first responder the same way for a one-window app.
extension UIResponder {
  private static weak var found: UIResponder?

  static var current: UIResponder? {
    found = nil
    UIApplication.shared.sendAction(#selector(captureFirstResponder), to: nil, from: nil, for: nil)
    return found
  }

  @objc private func captureFirstResponder() {
    UIResponder.found = self
  }
}
