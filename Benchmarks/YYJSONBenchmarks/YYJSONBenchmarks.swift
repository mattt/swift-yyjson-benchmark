import Benchmark
import Foundation
import YYJSON

// MARK: - Test Data Structures

struct SimpleStruct: Codable, Equatable {
    let name: String
    let age: Int
    let score: Double
    let isActive: Bool
}

struct NestedStruct: Codable, Equatable {
    struct Inner: Codable, Equatable {
        let value: String
        let count: Int
    }

    let id: Int
    let title: String
    let inner: Inner
    let tags: [String]
    let metadata: [String: String]
}

struct LargeStruct: Codable, Equatable {
    struct Level3: Codable, Equatable {
        let data: String
        let number: Int
    }

    struct Level2: Codable, Equatable {
        let items: [Level3]
        let description: String
    }

    struct Level1: Codable, Equatable {
        let sections: [Level2]
        let name: String
    }

    let root: [Level1]
    let timestamp: Double
}

// MARK: - Fixtures

let simpleStruct = SimpleStruct(
    name: "Test User",
    age: 30,
    score: 95.5,
    isActive: true
)

let nestedStruct = NestedStruct(
    id: 123,
    title: "Test Item",
    inner: NestedStruct.Inner(value: "inner value", count: 42),
    tags: ["tag1", "tag2", "tag3"],
    metadata: ["key1": "value1", "key2": "value2"]
)

let largeStruct: LargeStruct = {
    let level3Items = (0 ..< 10).map { i in
        LargeStruct.Level3(data: "Data \(i)", number: i)
    }
    let level2Sections = (0 ..< 5).map { i in
        LargeStruct.Level2(items: level3Items, description: "Section \(i)")
    }
    let level1Root = (0 ..< 3).map { i in
        LargeStruct.Level1(sections: level2Sections, name: "Root \(i)")
    }
    return LargeStruct(root: level1Root, timestamp: Date().timeIntervalSince1970)
}()

// JSON fixtures for decoding benchmarks
let simpleJSONData: Data = {
    try! JSONEncoder().encode(simpleStruct)
}()

let nestedJSONData: Data = {
    try! JSONEncoder().encode(nestedStruct)
}()

let largeJSONData: Data = {
    try! JSONEncoder().encode(largeStruct)
}()

// Foundation objects for serialization benchmarks
nonisolated(unsafe) let simpleFoundationObject: [String: Any] = [
    "name": "Test User",
    "age": 30,
    "score": 95.5,
    "isActive": true,
]

nonisolated(unsafe) let nestedFoundationObject: [String: Any] = [
    "id": 123,
    "title": "Test Item",
    "inner": [
        "value": "inner value",
        "count": 42,
    ] as [String: Any],
    "tags": ["tag1", "tag2", "tag3"],
    "metadata": [
        "key1": "value1",
        "key2": "value2",
    ] as [String: String],
]

nonisolated(unsafe) let largeFoundationObject: [String: Any] = {
    var root: [[String: Any]] = []
    for i in 0 ..< 3 {
        var sections: [[String: Any]] = []
        for j in 0 ..< 5 {
            var items: [[String: Any]] = []
            for k in 0 ..< 10 {
                items.append([
                    "data": "Data \(k)",
                    "number": k,
                ])
            }
            sections.append([
                "items": items,
                "description": "Section \(j)",
            ])
        }
        root.append([
            "sections": sections,
            "name": "Root \(i)",
        ])
    }
    return [
        "root": root,
        "timestamp": Date().timeIntervalSince1970,
    ] as [String: Any]
}()

// MARK: - Benchmark Entry Point

let benchmarks: @Sendable () -> Void = {
    // Include fixture benchmarks (for real-world JSON files)
    fixtureBenchmarks()

    // Number-heavy Codable decode benchmarks (isolates the cost of
    // YYJSON_READ_NUMBER_AS_RAW vs native numeric extraction)
    numberDecodingBenchmarks()

    // MARK: - Encoder Benchmarks (YYJSONEncoder vs JSONEncoder)

    Benchmark("Encoder/Simple/YYJSON") { benchmark in
        let encoder = YYJSONEncoder()
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! encoder.encode(simpleStruct))
        }
    }

    Benchmark("Encoder/Simple/Foundation") { benchmark in
        let encoder = JSONEncoder()
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! encoder.encode(simpleStruct))
        }
    }

    Benchmark("Encoder/Nested/YYJSON") { benchmark in
        let encoder = YYJSONEncoder()
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! encoder.encode(nestedStruct))
        }
    }

    Benchmark("Encoder/Nested/Foundation") { benchmark in
        let encoder = JSONEncoder()
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! encoder.encode(nestedStruct))
        }
    }

    Benchmark("Encoder/Large/YYJSON") { benchmark in
        let encoder = YYJSONEncoder()
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! encoder.encode(largeStruct))
        }
    }

    Benchmark("Encoder/Large/Foundation") { benchmark in
        let encoder = JSONEncoder()
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! encoder.encode(largeStruct))
        }
    }

    // MARK: - Decoder Benchmarks (YYJSONDecoder vs JSONDecoder)

    Benchmark("Decoder/Simple/YYJSON") { benchmark in
        let decoder = YYJSONDecoder()
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! decoder.decode(SimpleStruct.self, from: simpleJSONData))
        }
    }

    Benchmark("Decoder/Simple/Foundation") { benchmark in
        let decoder = JSONDecoder()
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! decoder.decode(SimpleStruct.self, from: simpleJSONData))
        }
    }

    Benchmark("Decoder/Nested/YYJSON") { benchmark in
        let decoder = YYJSONDecoder()
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! decoder.decode(NestedStruct.self, from: nestedJSONData))
        }
    }

    Benchmark("Decoder/Nested/Foundation") { benchmark in
        let decoder = JSONDecoder()
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! decoder.decode(NestedStruct.self, from: nestedJSONData))
        }
    }

    Benchmark("Decoder/Large/YYJSON") { benchmark in
        let decoder = YYJSONDecoder()
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! decoder.decode(LargeStruct.self, from: largeJSONData))
        }
    }

    Benchmark("Decoder/Large/Foundation") { benchmark in
        let decoder = JSONDecoder()
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! decoder.decode(LargeStruct.self, from: largeJSONData))
        }
    }

    // MARK: - Serialization Benchmarks (YYJSONSerialization vs JSONSerialization)

    Benchmark("Serialization/Read/Simple/YYJSON") { benchmark in
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! YYJSONSerialization.jsonObject(with: simpleJSONData))
        }
    }

    Benchmark("Serialization/Read/Simple/Foundation") { benchmark in
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! JSONSerialization.jsonObject(with: simpleJSONData))
        }
    }

    Benchmark("Serialization/Read/Nested/YYJSON") { benchmark in
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! YYJSONSerialization.jsonObject(with: nestedJSONData))
        }
    }

    Benchmark("Serialization/Read/Nested/Foundation") { benchmark in
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! JSONSerialization.jsonObject(with: nestedJSONData))
        }
    }

    Benchmark("Serialization/Read/Large/YYJSON") { benchmark in
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! YYJSONSerialization.jsonObject(with: largeJSONData))
        }
    }

    Benchmark("Serialization/Read/Large/Foundation") { benchmark in
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! JSONSerialization.jsonObject(with: largeJSONData))
        }
    }

    Benchmark("Serialization/Write/Simple/YYJSON") { benchmark in
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(
                try! YYJSONSerialization.data(withJSONObject: simpleFoundationObject)
            )
        }
    }

    Benchmark("Serialization/Write/Simple/Foundation") { benchmark in
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! JSONSerialization.data(withJSONObject: simpleFoundationObject))
        }
    }

    Benchmark("Serialization/Write/Nested/YYJSON") { benchmark in
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(
                try! YYJSONSerialization.data(withJSONObject: nestedFoundationObject)
            )
        }
    }

    Benchmark("Serialization/Write/Nested/Foundation") { benchmark in
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! JSONSerialization.data(withJSONObject: nestedFoundationObject))
        }
    }

    Benchmark("Serialization/Write/Large/YYJSON") { benchmark in
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(
                try! YYJSONSerialization.data(withJSONObject: largeFoundationObject)
            )
        }
    }

    Benchmark("Serialization/Write/Large/Foundation") { benchmark in
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! JSONSerialization.data(withJSONObject: largeFoundationObject))
        }
    }

    // MARK: - Direct Value API Benchmarks

    Benchmark("Value/Parse/Simple") { benchmark in
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! YYJSONValue(data: simpleJSONData))
        }
    }

    Benchmark("Value/Parse/Nested") { benchmark in
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! YYJSONValue(data: nestedJSONData))
        }
    }

    Benchmark("Value/Parse/Large") { benchmark in
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! YYJSONValue(data: largeJSONData))
        }
    }

    Benchmark(
        "Value/Access/Simple",
        configuration: .init(warmupIterations: 1)
    ) { benchmark in
        let value = try! YYJSONValue(data: simpleJSONData)
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(value["name"])
            Benchmark.blackHole(value["age"])
            Benchmark.blackHole(value["score"])
            Benchmark.blackHole(value["isActive"])
        }
    }

    Benchmark(
        "Value/Access/Nested",
        configuration: .init(warmupIterations: 1)
    ) { benchmark in
        let value = try! YYJSONValue(data: nestedJSONData)
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(value["id"])
            Benchmark.blackHole(value["title"])
            Benchmark.blackHole(value["inner"]?["value"])
            Benchmark.blackHole(value["inner"]?["count"])
            Benchmark.blackHole(value["tags"])
            Benchmark.blackHole(value["metadata"])
        }
    }

    Benchmark(
        "Value/Iterate/Object",
        configuration: .init(warmupIterations: 1)
    ) { benchmark in
        let value = try! YYJSONValue(data: nestedJSONData)
        guard let object = value.object else { return }
        for _ in benchmark.scaledIterations {
            for (key, val) in object {
                Benchmark.blackHole(key)
                Benchmark.blackHole(val)
            }
        }
    }

    Benchmark(
        "Value/Iterate/Array",
        configuration: .init(warmupIterations: 1)
    ) { benchmark in
        let value = try! YYJSONValue(data: nestedJSONData)
        guard let tags = value["tags"]?.array else { return }
        for _ in benchmark.scaledIterations {
            for tag in tags {
                Benchmark.blackHole(tag)
            }
        }
    }

    Benchmark(
        "Value/DeepAccess/Large",
        configuration: .init(warmupIterations: 1)
    ) { benchmark in
        let value = try! YYJSONValue(data: largeJSONData)
        for _ in benchmark.scaledIterations {
            if let root = value["root"]?.array {
                for rootItem in root {
                    if let name = rootItem["name"]?.string {
                        Benchmark.blackHole(name)
                    }
                    if let sections = rootItem["sections"]?.array {
                        for section in sections {
                            if let description = section["description"]?.string {
                                Benchmark.blackHole(description)
                            }
                            if let items = section["items"]?.array {
                                for item in items {
                                    Benchmark.blackHole(item["data"]?.string)
                                    Benchmark.blackHole(item["number"]?.number)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
