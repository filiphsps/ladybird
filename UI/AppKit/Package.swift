// swift-tools-version:5.9
//
// This file exists solely for SourceKit-LSP autocompletion in editors.
// The real build is driven by CMake. Do not use `swift build`.

import PackageDescription

let package = Package(
    name: "Ladybird",
    platforms: [.macOS(.v14)],
)
