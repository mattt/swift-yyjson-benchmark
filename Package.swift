// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-yyjson-benchmark",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/ordo-one/package-benchmark", from: "1.29.0"),
        .package(path: "../swift-yyjson"),
    ],
    targets: [
        .executableTarget(
            name: "YYJSONBenchmarks",
            dependencies: [
                .product(name: "Benchmark", package: "package-benchmark"),
                .product(name: "YYJSON", package: "swift-yyjson"),
            ],
            path: "Benchmarks/YYJSONBenchmarks",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
            ]
        )
    ]
)
