import Benchmark
import Foundation
import YYJSON

// MARK: - Fixture Loading

private func loadFixture(_ name: String) -> Data? {
    let fixturesPath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures")
        .appendingPathComponent(name)

    return try? Data(contentsOf: fixturesPath)
}

// Lazy-loaded fixtures
private let twitterJSON: Data? = loadFixture("twitter.json")
private let citmCatalogJSON: Data? = loadFixture("citm_catalog.json")
private let canadaJSON: Data? = loadFixture("canada.json")

// MARK: - Fixture Benchmarks

let fixtureBenchmarks: @Sendable () -> Void = {

    // MARK: - twitter.json (~632KB, typical API response with nested objects and CJK text)

    if let data = twitterJSON {
        // Parsing benchmarks
        Benchmark("Fixture/twitter.json/Parse/YYJSON") { benchmark in
            for _ in benchmark.scaledIterations {
                Benchmark.blackHole(try! YYJSONValue(data: data))
            }
        }

        Benchmark(
            "Fixture/twitter.json/Parse/YYJSON+in-place",
            configuration: .init(warmupIterations: 0, scalingFactor: .kilo)
        ) { benchmark in
            for _ in benchmark.scaledIterations {
                var copy = Data(data)
                benchmark.startMeasurement()
                Benchmark.blackHole(try! YYJSONValue.parseInPlace(consuming: &copy))
            }
        }

        Benchmark("Fixture/twitter.json/Parse/Foundation") { benchmark in
            for _ in benchmark.scaledIterations {
                Benchmark.blackHole(try! JSONSerialization.jsonObject(with: data))
            }
        }

        // Access benchmark - traverse the parsed structure
        Benchmark(
            "Fixture/twitter.json/Access/YYJSON",
            configuration: .init(warmupIterations: 1)
        ) { benchmark in
            let value = try! YYJSONValue(data: data)
            for _ in benchmark.scaledIterations {
                // Traverse statuses array
                if let statuses = value["statuses"]?.array {
                    for status in statuses {
                        Benchmark.blackHole(status["id"]?.number)
                        Benchmark.blackHole(status["text"]?.string)
                        Benchmark.blackHole(status["user"]?["screen_name"]?.string)
                        Benchmark.blackHole(status["retweet_count"]?.number)
                    }
                }
            }
        }

        Benchmark(
            "Fixture/twitter.json/Access/Foundation",
            configuration: .init(warmupIterations: 1)
        ) { benchmark in
            let value = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
            for _ in benchmark.scaledIterations {
                if let statuses = value["statuses"] as? [[String: Any]] {
                    for status in statuses {
                        Benchmark.blackHole(status["id"] as? Int)
                        Benchmark.blackHole(status["text"] as? String)
                        if let user = status["user"] as? [String: Any] {
                            Benchmark.blackHole(user["screen_name"] as? String)
                        }
                        Benchmark.blackHole(status["retweet_count"] as? Int)
                    }
                }
            }
        }
    }

    // MARK: - citm_catalog.json (~1.7MB, large catalog with many string keys)

    if let data = citmCatalogJSON {
        Benchmark("Fixture/citm_catalog.json/Parse/YYJSON") { benchmark in
            for _ in benchmark.scaledIterations {
                Benchmark.blackHole(try! YYJSONValue(data: data))
            }
        }

        Benchmark(
            "Fixture/citm_catalog.json/Parse/YYJSON+in-place",
            configuration: .init(warmupIterations: 0, scalingFactor: .kilo)
        ) { benchmark in
            for _ in benchmark.scaledIterations {
                var copy = Data(data)
                benchmark.startMeasurement()
                Benchmark.blackHole(try! YYJSONValue.parseInPlace(consuming: &copy))
            }
        }

        Benchmark("Fixture/citm_catalog.json/Parse/Foundation") { benchmark in
            for _ in benchmark.scaledIterations {
                Benchmark.blackHole(try! JSONSerialization.jsonObject(with: data))
            }
        }

        // Access benchmark - traverse events and performances
        Benchmark(
            "Fixture/citm_catalog.json/Access/YYJSON",
            configuration: .init(warmupIterations: 1)
        ) { benchmark in
            let value = try! YYJSONValue(data: data)
            for _ in benchmark.scaledIterations {
                if let performances = value["performances"]?.array {
                    for perf in performances {
                        Benchmark.blackHole(perf["eventId"]?.number)
                        Benchmark.blackHole(perf["start"]?.number)
                        if let prices = perf["prices"]?.array {
                            for price in prices {
                                Benchmark.blackHole(price["amount"]?.number)
                            }
                        }
                    }
                }
            }
        }

        Benchmark(
            "Fixture/citm_catalog.json/Access/Foundation",
            configuration: .init(warmupIterations: 1)
        ) { benchmark in
            let value = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
            for _ in benchmark.scaledIterations {
                if let performances = value["performances"] as? [[String: Any]] {
                    for perf in performances {
                        Benchmark.blackHole(perf["eventId"] as? Int)
                        Benchmark.blackHole(perf["start"] as? Int)
                        if let prices = perf["prices"] as? [[String: Any]] {
                            for price in prices {
                                Benchmark.blackHole(price["amount"] as? Int)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - canada.json (~2.2MB, GeoJSON with many coordinates - number heavy)

    if let data = canadaJSON {
        Benchmark("Fixture/canada.json/Parse/YYJSON") { benchmark in
            for _ in benchmark.scaledIterations {
                Benchmark.blackHole(try! YYJSONValue(data: data))
            }
        }

        Benchmark(
            "Fixture/canada.json/Parse/YYJSON+in-place",
            configuration: .init(warmupIterations: 0, scalingFactor: .kilo)
        ) { benchmark in
            for _ in benchmark.scaledIterations {
                var copy = Data(data)
                benchmark.startMeasurement()
                Benchmark.blackHole(try! YYJSONValue.parseInPlace(consuming: &copy))
            }
        }

        Benchmark("Fixture/canada.json/Parse/Foundation") { benchmark in
            for _ in benchmark.scaledIterations {
                Benchmark.blackHole(try! JSONSerialization.jsonObject(with: data))
            }
        }

        // Access benchmark - traverse coordinates (this is a GeoJSON with deeply nested arrays)
        Benchmark(
            "Fixture/canada.json/Access/YYJSON",
            configuration: .init(warmupIterations: 1)
        ) { benchmark in
            let value = try! YYJSONValue(data: data)
            for _ in benchmark.scaledIterations {
                // GeoJSON structure: features[].geometry.coordinates
                if let features = value["features"]?.array {
                    for feature in features {
                        if let geometry = feature["geometry"],
                            let coordinates = geometry["coordinates"]?.array
                        {
                            for coord in coordinates {
                                if let innerCoords = coord.array {
                                    for innerCoord in innerCoords {
                                        if let point = innerCoord.array {
                                            Benchmark.blackHole(point[0]?.number)
                                            Benchmark.blackHole(point[1]?.number)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Benchmark(
            "Fixture/canada.json/Access/Foundation",
            configuration: .init(warmupIterations: 1)
        ) { benchmark in
            let value = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
            for _ in benchmark.scaledIterations {
                if let features = value["features"] as? [[String: Any]] {
                    for feature in features {
                        if let geometry = feature["geometry"] as? [String: Any],
                            let coordinates = geometry["coordinates"] as? [Any]
                        {
                            for coord in coordinates {
                                if let innerCoords = coord as? [Any] {
                                    for innerCoord in innerCoords {
                                        if let point = innerCoord as? [Double] {
                                            Benchmark.blackHole(point[0])
                                            Benchmark.blackHole(point[1])
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
