import SwiftUI
import AppKit

struct HelpPopupView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                }
            
            // Help popup window
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Help")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
                .background(Color.appSurface(from: paletteManager))
                
                Divider()
                
                // Help content
                ScrollView {
                    HelpView()
                        .padding(24)
                }
                .background(Color.appSurface(from: paletteManager))
            }
            .frame(width: 600, height: 500)
            .background(Color.appSurface(from: paletteManager))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
    }
}

// // #Preview {
//     HelpPopupView(isPresented: .constant(true))
// }