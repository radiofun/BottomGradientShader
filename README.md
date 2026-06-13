# BottomGradientShader

A small SwiftUI + Metal experiment that renders a soft, animated ambient light rising from the bottom edge of the screen.

The effect is built as a SwiftUI `layerEffect` powered by a stitchable Metal shader. It is useful for notification reveals, game/controller UI, media surfaces, or any interface that needs a subtle underglow without using image assets.

## Preview

The project includes two views:

- `BottomAmbientLightView`: the reusable shader-backed ambient light view.
- `BottomAmbientLightDemoView`: a demo composition with a toggle button, glass UI, and an animated reveal sequence.

Open `BottomAmbientLightView.swift` in Xcode and use the `Bottom Ambient Light` SwiftUI preview to see the full demo.

## Requirements

- Xcode with SwiftUI shader support
- A platform that supports SwiftUI `layerEffect`
- The project is configured for iOS, iPadOS, macOS, and visionOS simulator/device targets

The demo uses newer SwiftUI visual effects such as `glassEffect`, so use a recent Xcode and SDK.

## Usage

Add `BottomAmbientLightView.swift` and `BottomAmbientShader.metal` to your target, then place the view behind your content:

```swift
ZStack {
    Color.black.ignoresSafeArea()

    BottomAmbientLightView(tint: .cyan, progress: 1)
        .ignoresSafeArea()

    YourContent()
}
```

Use `progress` to reveal or hide the light:

```swift
@State private var progress: CGFloat = 0

BottomAmbientLightView(tint: .white, progress: progress)
    .ignoresSafeArea()
    .onAppear {
        withAnimation(.easeOut(duration: 1.15)) {
            progress = 1
        }
    }
```

## Customization

The most useful controls are:

- `tint`: changes the color of the glow.
- `progress`: animates the organic upward reveal from `0` to `1`.
- `time`: passed from `TimelineView(.animation)` to keep the mist, motes, and glow drifting.

For deeper changes, edit `BottomAmbientShader.metal`:

- `deepBloom`, `upperMist`, and `verticalFade` control how far the light travels upward.
- `sourceGlow` and the three source centers shape the broad bottom light.
- `wisps`, `lightPockets`, and `motes` control the animated texture.
- `volumeAlpha` and `moteAlpha` control final intensity.

## Project Structure

```text
BottomGradientShader/
├── BottomAmbientLightView.swift
├── BottomAmbientShader.metal
├── BottomGradientShaderApp.swift
└── Assets.xcassets/
```

## Notes

The shader samples a simple white rectangle as its source layer, then writes the animated light into the returned color and alpha. This keeps the SwiftUI side small while letting Metal handle the organic shape, noise, and movement.
