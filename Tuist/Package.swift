// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        // Customize the product types for given package product
        // Default is .staticFramework
        // productTypes: ["Alamofire": .framework,] 
    )
#endif

let package = Package(
    name: "PackageName",
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0"),
    ]
)