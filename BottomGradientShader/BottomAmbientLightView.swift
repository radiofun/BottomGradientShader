//
//  BottomAmbientLightView.swift
//  SwiftJun1
//
//  Created by Codex on 5/31/26.
//

import SwiftUI

struct BottomAmbientLightView: View {
    var tint: Color = .cyan
    var progress: CGFloat = 1

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.white)
                    .layerEffect(
                        ShaderLibrary.bottomAmbientLighting(
                            .float2(
                                Float(geometry.size.width),
                                Float(geometry.size.height)
                            ),
                            .float(
                                timeline.date.timeIntervalSinceReferenceDate
                                    .truncatingRemainder(dividingBy: 100_000)
                            ),
                            .float(Float(progress)),
                            .color(tint)
                        ),
                        maxSampleOffset: .zero
                    )
            }
        }
    }
}

struct BottomAmbientLightDemoView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var lightReveal: CGFloat = 0
    @State private var lightOpacity = 0.0
    @State private var isContentVisible = false
    @State private var isUpdatePresented = true
    @State private var introSequence = 0
    @State private var tint: Color = .white

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            Image("sample2")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .frame(width:393)
                .opacity(isContentVisible ? 0.25 : 1)

            BottomAmbientLightView(tint: tint, progress: lightReveal)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Button {
                    toggleUpdate()
                } label: {
                    Text("toggle")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                }
                .glassEffect(.regular, in: .capsule)

                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "gamecontroller.fill")
                        .foregroundStyle(.white)
                        .padding()
                        .frame(width: 52, height: 52)
                        .glassEffect(
                            .clear.tint(.black.opacity(0.1)),
                            in: .rect(cornerRadius: 12)
                        )

                    VStack {
                        Text("Setting update")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.3))

                        Text("Controller Connected")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                }
                .padding(.horizontal, 24)
                .opacity(isContentVisible ? 1 : 0)
                .blur(radius: isContentVisible ? 0 : 28)
                .offset(y: isContentVisible ? -56 : 62)
                .scaleEffect(isContentVisible ? 1 : 0.96, anchor: .bottom)

            }
        }
        .task(id: introSequence) {
            guard isUpdatePresented else { return }
            await playIntro()
        }
    }

    @MainActor
    private func toggleUpdate() {
        isUpdatePresented.toggle()
        introSequence += 1

        guard !isUpdatePresented else { return }

        withAnimation(.easeOut(duration: 0.65)) {
            lightReveal = 0
            lightOpacity = 0
            isContentVisible = false
        }
    }

    @MainActor
    private func playIntro() async {
        lightReveal = 0
        lightOpacity = 0
        isContentVisible = false

        guard !reduceMotion else {
            lightReveal = 1
            lightOpacity = 0.82
            isContentVisible = true
            return
        }

        try? await Task.sleep(for: .milliseconds(120))
        guard !Task.isCancelled else { return }

        withAnimation(.easeOut(duration: 1.15)) {
            lightReveal = 1
            lightOpacity = 1
        }

        try? await Task.sleep(for: .milliseconds(280))
        guard !Task.isCancelled else { return }

        withAnimation(.spring(duration: 0.78, bounce: 0.16)) {
            isContentVisible = true
        }

        try? await Task.sleep(for: .milliseconds(680))
        guard !Task.isCancelled else { return }

        withAnimation(.easeOut(duration: 0.8)) {
            lightOpacity = 0.82
        }
    }
}

#Preview("Bottom Ambient Light") {
    BottomAmbientLightDemoView()
}
