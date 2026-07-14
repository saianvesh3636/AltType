---
name: theme-appearance-skill
description: Theme and visual customization system. Use when working with color schemes, appearance modes, theming, palette management, or visual customization. Covers PaletteManager, ColorProvider, and dynamic color system.
---

# Theme & Appearance - Visual Customization

## Overview

Dynamic theming system with support for light/dark modes and custom color palettes.

**Location**: `theTypeAlternative/Sources/`

**Key Component**: `PaletteManager+ColorProvider.swift`

## PaletteManager

```swift
public final class PaletteManager: ObservableObject {
    @Published var currentPalette: ColorPalette = .system

    public enum ColorPalette {
        case light
        case dark
        case system // Follows macOS appearance
    }

    func primaryColor(for colorScheme: ColorScheme) -> Color {
        switch currentPalette {
        case .light:
            return .blue
        case .dark:
            return .cyan
        case .system:
            return colorScheme == .dark ? .cyan : .blue
        }
    }
}
```

## ColorProvider Protocol

```swift
protocol ColorProvider {
    var primaryColor: Color { get }
    var secondaryColor: Color { get }
    var backgroundColor: Color { get }
    var textColor: Color { get }
    var accentColor: Color { get }
}

extension PaletteManager: ColorProvider {
    var primaryColor: Color {
        primaryColor(for: currentColorScheme)
    }
}
```

## Usage in Views

```swift
struct MyView: View {
    @StateObject private var paletteManager = PaletteManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            Text("Hello")
                .foregroundColor(paletteManager.primaryColor(for: colorScheme))
        }
        .background(paletteManager.backgroundColor)
    }
}
```

## Appearance Settings UI

```swift
struct AppearanceDetailView: View {
    @StateObject private var paletteManager = PaletteManager.shared

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $paletteManager.currentPalette) {
                    Text("Light").tag(ColorPalette.light)
                    Text("Dark").tag(ColorPalette.dark)
                    Text("System").tag(ColorPalette.system)
                }
                .pickerStyle(.radioGroup)
            }
        }
    }
}
```

## Related Skills
- **settings-ui-skill**: Appearance settings UI
- **user-feedback-skill**: Menu bar icon colors
