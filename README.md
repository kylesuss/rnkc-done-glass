# DoneBar: `KeyboardExtender` vs native keyboard accessories on iOS 26

A tiny native iOS app that compares, side by side on an iOS 26 simulator:

- what a **stock `UIToolbar` input accessory** looks like under Liquid Glass, and
- what **react-native-keyboard-controller's `KeyboardExtender`** produces, using the library's own
  unmodified `KeyboardExtenderContainerView.swift` from **1.22.8** —

plus a proposed `glass` prop that lets `KeyboardExtender` match the native look.

## The problem

On iOS 26+, `KeyboardExtenderContainerView.create` always returns `ModernContainerView`, which wraps
whatever the JS children render in a full-width, gray-tinted glass capsule. Nothing on the JS side
can reach it; the only switch is the app-wide `UIDesignRequiresCompatibility` flag, which turns
Liquid Glass off everywhere.

That matches iOS for bars with several controls, but not for a lone trailing button. A stock
`UIToolbar` accessory with one trailing item draws that item as **its own floating glass button**,
with no bar behind it. Apps that want a single "Done" can't get that look from `KeyboardExtender`.

## What's in the app

| Section | Rows |
| --- | --- |
| Transitions | "No bar" field, native Done, RNKC stock, RNKC + `glass={false}` — for focus-switch comparisons |
| react-native-keyboard-controller | Stock + tinted pill content, stock + text "Done", proposed `glass={false}` + tinted pill |
| Native · UIToolbar | stock `.done`, "Done" + `.prominent`, checkmark, checkmark + `.prominent` |
| Native · SwiftUI | `.keyboard` toolbar, plain and `.glassProminent` |

The RNKC rows are wired the way `KeyboardExtenderManager.mm` wires them: a `_contentView` whose first
subview is the full-width JS root (`<View style={{ width }}>`), handed to
`KeyboardExtenderContainerView.create(frame:contentView:)` sized to that subview's height, attached
on `textDidBeginEditing` and followed by `reloadInputViews`. The tinted pill is a `UIGlassEffect`
view, which is what `@callstack/liquid-glass`'s `LiquidGlassView` renders from JS.
`Sources/RNKCShims.swift` stands in for RNKC's `UIResponder.current`. The JS layer itself isn't
running; it only wraps the children in a full-width `View`, so the native container decides the look.

## Findings (iPhone 17 Pro simulator)

**Shape.** Native lone item = floating glass button, no bar. RNKC stock = the same content inside a
full-width gray capsule, whatever the content is. RNKC + `glass={false}` = matches native.

| Native "Done" `.prominent` | RNKC 1.22.8 stock, tinted pill | RNKC + `glass={false}` |
| --- | --- | --- |
| ![](media/ios26/kb-prom-done.png) | ![](media/ios26/rnkc-stock-pill.png) | ![](media/ios26/rnkc-patched-pill.png) |

The stock `.done` system item draws as a tinted ✓ circle (`media/ios26/kb-sys-done.png`). iOS 27
(built with Xcode 27) behaves the same; see `media/ios27/`.

**Spacing.** Native `UIToolbar` / SwiftUI `.keyboard` accessories sit **flush** on the keyboard on
both iOS 26 (Xcode 26.1.1) and iOS 27 (Xcode 27.0). That's a known, still-open Apple issue
([forum thread](https://developer.apple.com/forums/thread/797250), FB22938104). Apple's own surfaces
leave a gap: Safari's form accessory floats **10pt** above the keyboard
(`media/references/safari-form-bar-ios26.png`). `ModernContainerView`'s existing `paddingBottom`
gives the same 10pt, and the proposal keeps it, so `glass={false}` only changes the material.

**Transitions** (no bar → bar → no bar, `media/transitions/`). Exit is instant for native, stock
and patched alike. Enter is about 150–170ms for all three. Native glass grows out of the keyboard
edge, while RNKC's container slides up from behind it.

## The proposal

`proposal/keyboard-extender-glass-prop.patch`, against **1.22.8** (`src/` + `ios/` only):

- `glass?: boolean` on `KeyboardExtender`, default `true`, so nothing changes for existing users.
  It's a codegen `WithDefault` prop, plus the old-architecture `RCT_EXPORT_VIEW_PROPERTY` and setter.
- `ModernContainerView` takes `glass`. With `false` it puts a plain view where the
  `UIGlassEffect` view goes, with the same frames: same 20pt horizontal inset math, same 10pt float.
- Changing the prop at runtime rebuilds the shared container and re-attaches it if enabled. This is
  needed when one screen switches between a bar that wants the capsule and one that doesn't.
- iOS-only, like the platform-labelled props in the `KeyboardGestureArea` docs. Android's extender
  has no glass container (it's `KeyboardStickyView` + `KeyboardBackgroundView`), so the prop is a
  no-op there.
- Not included yet: a `glass` entry in `docs/docs/api/views/keyboard-extender` (with the iOS label)
  and a `FabricExample` variant.

## Build and run

Requires Xcode 26+ and an iOS 26+ simulator.

```sh
./build.sh                        # booted simulator, /Applications/Xcode.app
./build.sh <UDID>                 # a specific simulator
XCODE="/Applications/Xcode 27.app" ./build.sh <UDID>
```

Turn on the software keyboard (I/O → Keyboard → Toggle Software Keyboard, ⌘K) to see placement.

## License

`vendor/rnkc-1.22.8/` holds unmodified files from react-native-keyboard-controller (MIT, © Kiryl
Ziusko, see `vendor/rnkc-1.22.8/LICENSE`). `vendor/rnkc-glass-prop/` is the same container file with
the proposal applied and the class renamed so both can build in one target.
