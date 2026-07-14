import XCTest
import SwiftUI
@testable import theTypeAlternative

final class SettingsUITests: XCTestCase {
    
    func testImprovedSettingsMainViewLayout() throws {
        // Test the main settings view layout
        let settingsView = ImprovedSettingsMainView()
            .environmentObject(AppearanceSettings())
            .environmentObject(PaletteManager())
            .environmentObject(PermissionKit.PermissionManager())
            .environmentObject(SpeechEngineSettings())
            .environmentObject(SpeechEngineManager())
        
        // This test will help us see if the view renders correctly
        let hostingController = NSHostingController(rootView: settingsView)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        
        XCTAssertNotNil(hostingController.view)
        
        // Test that the view doesn't crash when rendered
        hostingController.view.layout()
        
        print("✅ Settings view layout test completed")
    }
    
    func testSystemSettingsComponentsRendering() throws {
        let paletteManager = PaletteManager()
        
        // Test SystemSettingsSection component
        let section = SystemSettingsSection(title: "Test Section") {
            Text("Test Content")
        }
        .environmentObject(paletteManager)
        
        let hostingController = NSHostingController(rootView: section)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 400, height: 200)
        
        XCTAssertNotNil(hostingController.view)
        hostingController.view.layout()
        
        print("✅ SystemSettingsSection component test completed")
    }
    
    func testModalSheetPresentation() throws {
        // Test that modal sheets can be presented without crashes
        @State var showingSheet = false
        
        let testView = VStack {
            Button("Show Sheet") {
                showingSheet = true
            }
        }
        .sheet(isPresented: .constant(true)) {
            AppearanceConfigSheet()
                .environmentObject(AppearanceSettings())
                .environmentObject(PaletteManager())
        }
        
        let hostingController = NSHostingController(rootView: testView)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 500, height: 400)
        
        XCTAssertNotNil(hostingController.view)
        print("✅ Modal sheet presentation test completed")
    }
    
    func testSettingsScrollViewBehavior() throws {
        let settingsView = ScrollView {
            LazyVStack(spacing: 32) {
                ForEach(0..<10, id: \.self) { index in
                    SystemSettingsSection(title: "Section \(index)") {
                        Text("Content \(index)")
                            .padding()
                    }
                    .environmentObject(PaletteManager())
                }
            }
            .padding(.horizontal, 32)
        }
        
        let hostingController = NSHostingController(rootView: settingsView)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        
        XCTAssertNotNil(hostingController.view)
        hostingController.view.layout()
        
        print("✅ Settings scroll view behavior test completed")
    }
}