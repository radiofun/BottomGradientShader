//
//  BottomAmbientShader.metal
//  SwiftJun1
//
//  Created by Codex on 5/31/26.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

float bottomAmbientRandom(float seed) {
    return fract(sin(seed) * 43758.5453);
}

float bottomAmbientSoftCircle(float2 point, float2 center, float radius, float blur) {
    return 1.0 - smoothstep(radius, radius + blur, distance(point, center));
}

[[ stitchable ]] half4 bottomAmbientLighting(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    float progress,
    half4 tint
) {
    float2 uv = position / max(size, float2(1.0));
    float aspectRatio = size.x / max(size.y, 1.0);
    float revealProgress = smoothstep(0.0, 1.0, saturate(progress));

    float bottomDistance = 1.0 - uv.y;
    float verticalFade = 1.0 - smoothstep(0.0, 0.62, bottomDistance);
    float deepBloom = exp(-bottomDistance * 4.4);
    float upperMist = exp(-bottomDistance * 3.0) * 0.2;

    // Wide overlapping sources avoid a single visible flame or spotlight shape.
    float horizontalFlow = sin(uv.x * 4.2 + time * 5.5) * 0.08;
    horizontalFlow += sin(uv.x * 9.0 - time * 0.38) * 0.035;
    float wideSource = 0.72 + sin(uv.x * 5.4 - time * 0.72) * 0.12;
    wideSource += sin(uv.x * 12.0 + time * 0.42) * 0.06;

    float2 leftCenter = float2(0.08 + horizontalFlow, 1.08);
    float2 middleCenter = float2(0.52 - horizontalFlow * 0.45, 1.12);
    float2 rightCenter = float2(0.94 + horizontalFlow * 0.35, 1.06);
    float leftGlow = 1.0 - smoothstep(0.0, 0.88, distance(uv, leftCenter));
    float middleGlow = 1.0 - smoothstep(0.0, 1.04, distance(uv, middleCenter));
    float rightGlow = 1.0 - smoothstep(0.0, 0.82, distance(uv, rightCenter));
    float sourceGlow = leftGlow * 0.7 + middleGlow * 0.82 + rightGlow * 0.64;

    float risingNoise = sin(uv.x * 7.0 + bottomDistance * 9.0 - time * 0.78) * 0.08;
    risingNoise += sin(uv.x * 15.0 - bottomDistance * 5.0 + time * 0.56) * 0.045;
    float driftingMist = saturate(0.76 + risingNoise);
    float breathing = 0.92 + sin(time * 0.64) * 0.08;

    // Grow upward with a moving boundary instead of revealing a rectangular mask.
    float revealWarp = sin(uv.x * 5.0 - time * 1.4) * 0.055;
    revealWarp += sin(uv.x * 13.0 + time * 0.86) * 0.025;
    float revealHeight = mix(0.0, 0.86, revealProgress);
    float organicReveal = 1.0 - smoothstep(
        revealHeight - 0.14,
        revealHeight + 0.1,
        bottomDistance + revealWarp
    );
    organicReveal *= smoothstep(0.0, 0.12, revealProgress);

    // Ribbons and pockets rise at different speeds so the underlight feels alive.
    float wispWarp = uv.x;
    wispWarp += sin(uv.y * 7.0 - time * 1.35) * 0.085;
    wispWarp += sin(uv.y * 16.0 + time * 0.82) * 0.032;
    float risingBands = 0.5 + sin(
        bottomDistance * 15.0
            - time * 2.15
            + sin(wispWarp * 9.0 + time * 0.36) * 1.1
    ) * 0.5;
    risingBands *= 0.58 + sin(wispWarp * 13.0 - time * 0.68) * 0.24;
    float wisps = risingBands * exp(-bottomDistance * 3.2);

    float lightPockets = 0.0;
    for (ushort index = 0; index < 6; index++) {
        float seed = float(index) + 1.0;
        float speed = mix(0.07, 0.16, bottomAmbientRandom(seed * 3.7));
        float progress = fract(time * speed + bottomAmbientRandom(seed * 8.1));
        float pocketX = bottomAmbientRandom(seed * 2.9);
        pocketX += sin(time * 0.8 + seed * 1.7) * 0.08;
        float pocketY = mix(1.14, -0.16, progress);
        float2 pocketScale = float2(
            mix(0.18, 0.32, bottomAmbientRandom(seed * 5.3)),
            mix(0.12, 0.28, bottomAmbientRandom(seed * 6.7))
        );
        float2 pocketPoint = (uv - float2(pocketX, pocketY)) / pocketScale;
        float pocketFade = smoothstep(0.0, 0.15, progress)
            * (1.0 - smoothstep(0.52, 1.0, progress));
        lightPockets += exp(-dot(pocketPoint, pocketPoint) * 1.8) * pocketFade;
    }

    float volume = saturate(
        (deepBloom * 0.42 + upperMist) * sourceGlow * wideSource * driftingMist * breathing
            + wisps * sourceGlow * 0.13
            + lightPockets * exp(-bottomDistance * 3.0) * 0.24
            + verticalFade * 0.1
    ) * organicReveal;

    float motes = 0.0;
    float2 moteSpace = float2(uv.x * aspectRatio, uv.y);
    for (ushort index = 0; index < 18; index++) {
        float seed = float(index) + 1.0;
        float speed = mix(0.035, 0.09, bottomAmbientRandom(seed * 4.7));
        float progress = fract(time * speed + bottomAmbientRandom(seed * 8.9));
        float moteX = bottomAmbientRandom(seed * 2.3);
        moteX += sin(time * 0.62 + seed) * 0.025;
        float moteY = mix(1.04, 0.06, progress);
        float radius = mix(0.0001, 0.0005, bottomAmbientRandom(seed * 6.1));
        float moteFade = smoothstep(0.0, 0.16, progress)
            * (1.0 - smoothstep(0.48, 1.0, progress));
        float2 moteCenter = float2(moteX * aspectRatio, moteY);
        motes += bottomAmbientSoftCircle(moteSpace, moteCenter, radius, 0.005)
            * moteFade;
    }

    half volumeAlpha = half(saturate(volume * 0.48));
    half moteAlpha = half(saturate(motes * 0.14 * smoothstep(0.18, 0.72, revealProgress)));
    half sourceMask = layer.sample(position).a;
    volumeAlpha *= tint.a * sourceMask;
    moteAlpha *= sourceMask;
    half alpha = saturate(volumeAlpha + moteAlpha);

    return half4(tint.rgb * volumeAlpha + half3(1.0) * moteAlpha, alpha);
}
