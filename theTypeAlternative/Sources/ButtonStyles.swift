import SwiftUI

struct ModernToggleStyle: ToggleStyle {
    @EnvironmentObject var paletteManager: PaletteManager

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.appOnSurface(from: paletteManager))

            Spacer()

            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color.appPrimary(from: paletteManager) : Color.appOnSurface(from: paletteManager).opacity(0.3))
                .frame(width: 51, height: 31)
                .overlay(
                    Circle()
                        .fill(.white)
                        .frame(width: 27, height: 27)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

struct IconHoverButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isHovering = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : (isHovering && !reduceMotion ? 1.1 : 1.0))
            .opacity(configuration.isPressed ? 0.6 : (isHovering ? 0.8 : 0.7))
            .background(
                Circle()
                    .fill(isHovering ? Color.white.opacity(0.12) : Color.clear)
                    .scaleEffect(isHovering ? 1.3 : 1.0)
                    .animation(.easeInOut(duration: 0.25), value: isHovering)
            )
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
    }
}
