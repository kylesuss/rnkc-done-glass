import SwiftUI
import UIKit

@main
struct RNKCDoneGlassApp: App {
  var body: some Scene {
    WindowGroup { ContentView() }
  }
}

enum Variant: String {
  case systemDone, prominentDone, checkmark, prominentCheck
}

/// A decimal-pad UITextField whose inputAccessoryView is a stock UIToolbar with one trailing item.
struct UIKitField: UIViewRepresentable {
  let variant: Variant
  var testID: String? = nil

  func makeUIView(context: Context) -> UITextField {
    let field = UITextField()
    field.placeholder = "0.00"
    field.keyboardType = .decimalPad
    field.textAlignment = .right
    field.accessibilityIdentifier = testID ?? variant.rawValue

    let dismiss = UIAction { _ in field.resignFirstResponder() }
    var item: UIBarButtonItem
    switch variant {
    case .systemDone:
      item = UIBarButtonItem(systemItem: .done, primaryAction: dismiss)
    case .prominentDone:
      item = UIBarButtonItem(title: "Done", primaryAction: dismiss)
      item.style = .prominent
    case .checkmark:
      item = UIBarButtonItem(image: UIImage(systemName: "checkmark"), primaryAction: dismiss)
    case .prominentCheck:
      item = UIBarButtonItem(image: UIImage(systemName: "checkmark"), primaryAction: dismiss)
      item.style = .prominent
    }

    let toolbar = UIToolbar()
    toolbar.items = [UIBarButtonItem(systemItem: .flexibleSpace), item]
    toolbar.sizeToFit()
    field.inputAccessoryView = toolbar
    return field
  }

  func updateUIView(_ uiView: UITextField, context: Context) {}
}

/// A decimal-pad field with no accessory, to switch from/to.
struct NoBarField: UIViewRepresentable {
  func makeUIView(context: Context) -> UITextField {
    let field = UITextField()
    field.placeholder = "0.00"
    field.keyboardType = .decimalPad
    field.textAlignment = .right
    field.accessibilityIdentifier = "noBar"
    return field
  }

  func updateUIView(_ uiView: UITextField, context: Context) {}
}

struct ContentView: View {
  @State private var plain = ""
  @State private var prominent = ""
  @FocusState private var focused: Int?

  var body: some View {
    NavigationStack {
      Form {
        Section {
          LabeledContent("No bar") { NoBarField() }
          LabeledContent("Native · Done .prominent") {
            UIKitField(variant: .prominentDone, testID: "transNative")
          }
          LabeledContent("RNKC stock · pill") {
            RNKCField(variant: .stockTintedPill, testID: "transStock")
          }
          LabeledContent("RNKC patched · pill") {
            RNKCField(variant: .patchedTintedPill, testID: "transPatched")
          }
        } header: {
          Text("Transitions · tap No bar ↔ a bar row")
        } footer: {
          Text("RNKC rows attach on textDidBeginEditing + reloadInputViews, like KeyboardExtenderManager.mm.")
        }
        Section {
          LabeledContent("Stock · tinted pill") { RNKCField(variant: .stockTintedPill) }
          LabeledContent("Stock · text Done") { RNKCField(variant: .stockText) }
          LabeledContent("Patched · glass: false") { RNKCField(variant: .patchedTintedPill) }
        } header: {
          Text("react-native-keyboard-controller · KeyboardExtender")
        } footer: {
          Text("Unmodified KeyboardExtenderContainerView.swift from 1.22.8. Whatever the JS content is, iOS 26 wraps it in a full-width gray glass capsule; only the patched container leaves it bare.")
        }
        Section {
          LabeledContent("System .done") { UIKitField(variant: .systemDone) }
          LabeledContent("Done .prominent") { UIKitField(variant: .prominentDone) }
          LabeledContent("Checkmark") { UIKitField(variant: .checkmark) }
          LabeledContent("Checkmark .prominent") { UIKitField(variant: .prominentCheck) }
        } header: {
          Text("Native · UIToolbar inputAccessoryView")
        } footer: {
          Text("Stock UIKit. A lone trailing item floats on its own glass; no bar behind it.")
        }
        Section("Native · SwiftUI .keyboard toolbar") {
          TextField("Plain Done", text: $plain)
            .keyboardType(.decimalPad)
            .focused($focused, equals: 1)
            .accessibilityIdentifier("swiftuiPlain")
          TextField("glassProminent Done", text: $prominent)
            .keyboardType(.decimalPad)
            .focused($focused, equals: 2)
            .accessibilityIdentifier("swiftuiProminent")
        }
      }
      .navigationTitle("Done on glass")
      .toolbar {
        ToolbarItemGroup(placement: .keyboard) {
          Spacer()
          if focused == 2 {
            Button("Done") { focused = nil }.buttonStyle(.glassProminent)
          } else if focused == 1 {
            Button("Done") { focused = nil }
          }
        }
      }
    }
  }
}
