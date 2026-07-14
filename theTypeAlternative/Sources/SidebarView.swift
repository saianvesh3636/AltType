import SwiftUI

struct SidebarView: View {
    @Binding var selectedTab: SidebarItem
    @EnvironmentObject var paletteManager: PaletteManager

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(Color.appPrimary(from: paletteManager))
                .padding(.top, 20)
                .padding(.bottom, 20)

            VStack(spacing: 4) {
                ForEach(SidebarItem.allCases) { item in
                    SidebarItemView(
                        item: item,
                        isSelected: selectedTab == item
                    ) {
                        selectedTab = item
                    }
                }
            }
            .padding(.horizontal, 8)
            
            Spacer()
            
            // Footer
            VStack(spacing: 8) {
                Divider()
                    .padding(.horizontal, 16)
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Version \(AppConfiguration.appVersion)")
                            .font(.caption2)
                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                        
                        Text("© \(String(Calendar.current.component(.year, from: Date()))) AltType")
                            .font(.caption2)
                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(width: 200)
        .background(Color.appSurface(from: paletteManager))
    }
}

struct SidebarItemView: View {
    let item: SidebarItem
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? Color.appOnPrimary(from: paletteManager) : Color.appOnSurface(from: paletteManager))
                .frame(width: 20)
            
            Text(item.rawValue)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? Color.appOnPrimary(from: paletteManager) : Color.appOnSurface(from: paletteManager))
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.appPrimary(from: paletteManager) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                action()
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

struct SidebarBottomItemView: View {
    let title: String
    let icon: String
    let action: () -> Void
    @EnvironmentObject var paletteManager: PaletteManager

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                .frame(width: 20)

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                action()
            }
        }
    }
}

// // #Preview {
//     SidebarView(
//         selectedTab: .constant(.home),
//         showAccountOverlay: .constant(false)
//     )
//     .frame(height: 600)
// }