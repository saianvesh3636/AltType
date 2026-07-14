import XCTest
import SwiftUI
@testable import theTypeAlternative

/// Tests to validate modal sheet UI improvements
final class ModalSheetValidationTests: XCTestCase {
    
    func testAppearanceConfigSheetLayout() throws {
        let sheet = AppearanceConfigSheet()
            .environmentObject(AppearanceSettings())
            .environmentObject(PaletteManager())
        
        let hostingController = NSHostingController(rootView: sheet)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 400, height: 500)
        
        // Ensure the view can be created and laid out without crashes
        XCTAssertNotNil(hostingController.view)
        hostingController.view.layout()
        
        print("✅ AppearanceConfigSheet layout validation passed")
    }
    
    func testLanguageSelectionSheetLayout() throws {
        @State var selectedLanguage = "English (US)"
        
        let sheet = LanguageSelectionSheet(selectedLanguage: .constant(selectedLanguage))
            .environmentObject(PaletteManager())
        
        let hostingController = NSHostingController(rootView: sheet)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 300, height: 400)
        
        XCTAssertNotNil(hostingController.view)
        hostingController.view.layout()
        
        print("✅ LanguageSelectionSheet layout validation passed")
    }
    
    func testEngineSelectionSheetLayout() throws {
        let sheet = EngineSelectionSheet()
            .environmentObject(SpeechEngineSettings())
            .environmentObject(PaletteManager())
        
        let hostingController = NSHostingController(rootView: sheet)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 450, height: 400)
        
        XCTAssertNotNil(hostingController.view)
        hostingController.view.layout()
        
        print("✅ EngineSelectionSheet layout validation passed")
    }
    
    func testModelManagementSheetLayout() throws {
        let sheet = ModelManagementSheet()
            .environmentObject(SpeechEngineSettings())
            .environmentObject(SpeechEngineManager())
            .environmentObject(PaletteManager())
        
        let hostingController = NSHostingController(rootView: sheet)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 500, height: 500)
        
        XCTAssertNotNil(hostingController.view)
        hostingController.view.layout()
        
        print("✅ ModelManagementSheet layout validation passed")
    }
    
    func testStorageManagementSheetLayout() throws {
        let sheet = StorageManagementSheet()
            .environmentObject(SpeechEngineManager())
            .environmentObject(PaletteManager())
        
        let hostingController = NSHostingController(rootView: sheet)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
        
        XCTAssertNotNil(hostingController.view)
        hostingController.view.layout()
        
        print("✅ StorageManagementSheet layout validation passed")
    }
    
    func testImprovedSettingsMainViewLayout() throws {
        let mainView = ImprovedSettingsMainView()
            .environmentObject(AppearanceSettings())
            .environmentObject(PaletteManager())
            .environmentObject(PermissionKit.PermissionManager())
            .environmentObject(SpeechEngineSettings())
            .environmentObject(SpeechEngineManager())
        
        let hostingController = NSHostingController(rootView: mainView)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        
        XCTAssertNotNil(hostingController.view)
        hostingController.view.layout()
        
        print("✅ ImprovedSettingsMainView layout validation passed")
    }
    
    func testSystemSettingsComponentsLayout() throws {
        let section = SystemSettingsSection(title: "Test Section") {
            SystemSettingsRow {
                HStack {
                    Text("Test Setting")
                    Spacer()
                    Toggle("", isOn: .constant(true))
                }
            }
        }
        .environmentObject(PaletteManager())
        
        let hostingController = NSHostingController(rootView: section)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 400, height: 200)
        
        XCTAssertNotNil(hostingController.view)
        hostingController.view.layout()
        
        print("✅ SystemSettingsComponents layout validation passed")
    }
}