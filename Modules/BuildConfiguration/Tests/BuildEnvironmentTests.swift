import Testing
@testable import BuildConfiguration

struct BuildEnvironmentTests {
    
    @Test("Build environment current configuration")
    func testCurrentEnvironment() throws {
        // Test that current environment is correctly determined
        let currentEnv = BuildEnvironment.current
        
        #if DEBUG
        #expect(currentEnv == .debug)
        #expect(currentEnv.isDebug == true)
        #expect(currentEnv.isProduction == false)
        #expect(currentEnv.allowsDebugFeatures == true)
        #else
        #expect(currentEnv == .production)
        #expect(currentEnv.isDebug == false)
        #expect(currentEnv.isProduction == true)
        #expect(currentEnv.allowsDebugFeatures == false)
        #endif
    }
    
    @Test("Build environment properties")
    func testEnvironmentProperties() throws {
        // Test debug environment
        let debugEnv = BuildEnvironment.debug
        #expect(debugEnv.isDebug == true)
        #expect(debugEnv.isProduction == false)
        #expect(debugEnv.allowsDebugFeatures == true)
        #expect(debugEnv.bundleIdSuffix == ".debug")
        #expect(debugEnv.displayName == "Debug")
        
        // Test production environment
        let prodEnv = BuildEnvironment.production
        #expect(prodEnv.isDebug == false)
        #expect(prodEnv.isProduction == true)
        #expect(prodEnv.allowsDebugFeatures == false)
        #expect(prodEnv.bundleIdSuffix == "")
        #expect(prodEnv.displayName == "Production")
    }
    
    @Test("Build environment string values")
    func testEnvironmentStringValues() throws {
        #expect(BuildEnvironment.debug.rawValue == "DEBUG")
        #expect(BuildEnvironment.production.rawValue == "PRODUCTION")
    }
    
    @Test("Build environment case iteration")
    func testAllCases() throws {
        let allCases = BuildEnvironment.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.debug))
        #expect(allCases.contains(.production))
    }
}