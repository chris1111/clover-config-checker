// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CloverConfigCheckerApp",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "CloverConfigCheckerApp"),
        .testTarget(
            name: "CloverConfigCheckerAppTests",
            dependencies: ["CloverConfigCheckerApp"]
        )
    ]
)
