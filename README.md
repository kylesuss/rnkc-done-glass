# rnkc-done-glass

A native iOS app comparing `KeyboardExtender` with a stock `UIToolbar` keyboard accessory on
iOS 26, plus a proposed `glass` prop for `KeyboardExtender`.

## Problem

- On iOS 26+, `KeyboardExtender` always wraps its children in a full-width gray glass capsule.
- That comes from `ModernContainerView` in native code. JS can't remove it, and the only
  switch is `UIDesignRequiresCompatibility`, which turns off glass app-wide.
- A native `UIToolbar` accessory with one trailing item has no bar. It draws the item as its own
  floating glass button. With several items, iOS does group them into a shared capsule.

| Native `UIToolbar` | RNKC 1.22.8 | RNKC + `glass={false}` |
| --- | --- | --- |
| ![](media/ios26/kb-prom-done.png) | ![](media/ios26/rnkc-stock-pill.png) | ![](media/ios26/rnkc-patched-pill.png) |

## Proposal

[`proposal/keyboard-extender-glass-prop.patch`](proposal/keyboard-extender-glass-prop.patch), against 1.22.8:

- `glass?: boolean` on `KeyboardExtender`, default `true`, so existing apps are unchanged.
- iOS only. Android's extender has no glass container, so the prop does nothing there.
- With `false`, `ModernContainerView` keeps the same frames but uses a plain view instead of
  the `UIGlassEffect` one. The 10pt float above the keyboard stays.
- Changing it at runtime rebuilds the shared container and re-attaches it.
- Not in the patch yet: the docs entry and a `FabricExample` variant.

## Also measured

- **Spacing:** native toolbars sit flush on the keyboard, on iOS 26 and 27. That's an open Apple
  bug ([thread](https://developer.apple.com/forums/thread/797250), FB22938104). Safari's form
  bar floats 10pt, the same as RNKC's existing offset (`media/references/`).
- **Transitions:** exit is instant for native and RNKC. Enter takes about 150ms for both, but
  native glass grows in place while RNKC slides up from behind the keyboard
  (`media/transitions/`).
- **iOS 27:** same results (`media/ios27/`).

## How the repro works

- The RNKC rows use the library's own `KeyboardExtenderContainerView.swift`, unmodified from
  1.22.8 (`vendor/rnkc-1.22.8/`). The patched copy is in `vendor/rnkc-glass-prop/`.
- They're wired like `KeyboardExtenderManager.mm`: a full-width child content view, attached on
  `textDidBeginEditing`, then `reloadInputViews`.

## Run

```sh
./build.sh <simulator UDID>                           # Xcode 26+, iOS 26+ simulator
XCODE="/Applications/Xcode 27.app" ./build.sh <UDID>  # another toolchain
```

Press ⌘K in Simulator to show the software keyboard.
