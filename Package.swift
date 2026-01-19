 // swift-tools-version: 5.9
 import PackageDescription

 let package = Package(
     name: "Dockey",
     platforms: [.macOS(.v13)],
     products: [
         .library(name: "CoreKit", targets: ["CoreKit"]),
         .executable(name: "dockey", targets: ["dockey"])
     ],
     dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.27.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
     ],
     targets: [
         .target(
            name: "CoreKit",
            dependencies: [.product(name: "GRDB", package: "GRDB.swift")]
         ),
         .executableTarget(
             name: "dockey",
             dependencies: [
                 "CoreKit",
                 .product(name: "ArgumentParser", package: "swift-argument-parser")
             ]
         ),
         .testTarget(name: "CoreKitTests", dependencies: ["CoreKit"])
     ]
 )
