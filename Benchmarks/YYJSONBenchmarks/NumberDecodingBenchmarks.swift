import Benchmark
import Foundation
import YYJSON

// MARK: - Synthetic Number-Heavy Codable Fixtures

private let intCount = 10_000
private let doubleCount = 10_000

private let intArrayJSON: Data = {
    let ints = (0 ..< intCount).map { String($0 * 1_234_567) }
    return Data("[\(ints.joined(separator: ","))]".utf8)
}()

private let doubleArrayJSON: Data = {
    let doubles = (0 ..< doubleCount).map { i -> String in
        // Mix of integer, fractional, and exponent forms.
        let v = Double(i) * 0.1234567
        return String(v)
    }
    return Data("[\(doubles.joined(separator: ","))]".utf8)
}()

private let decimalArrayJSON: Data = doubleArrayJSON

// A struct that combines strings and ints in equal measure,
// to estimate the overhead amortized across a "typical" Codable type.
private struct Mixed: Codable {
    let name: String
    let age: Int
    let score: Double
    let count: Int
}

private let mixedArrayJSON: Data = {
    let items = (0 ..< intCount).map { i in
        "{\"name\":\"item_\(i)\",\"age\":\(i % 99),\"score\":\(Double(i) * 0.5),\"count\":\(i * 7)}"
    }
    return Data("[\(items.joined(separator: ","))]".utf8)
}()

// MARK: - canada.json fixture, projected to a number-only payload

private func loadFixture(_ name: String) -> Data? {
    let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures")
        .appendingPathComponent(name)
    return try? Data(contentsOf: url)
}

// Concatenate every coordinate pair in canada.json into one flat
// [[Double, Double]] array, then re-emit as JSON. Roughly 100k pairs
// (200k Doubles) — large enough to dominate, small enough to sample.
private let canadaCoordsJSON: Data? = {
    guard let data = loadFixture("canada.json"),
        let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let features = obj["features"] as? [[String: Any]]
    else { return nil }
    var pairs: [[Double]] = []
    pairs.reserveCapacity(120_000)
    for f in features {
        guard let geo = f["geometry"] as? [String: Any],
            let coords = geo["coordinates"] as? [[[Double]]]
        else { continue }
        for ring in coords {
            for p in ring where p.count == 2 {
                pairs.append(p)
            }
        }
    }
    return try? JSONSerialization.data(withJSONObject: pairs)
}()

// MARK: - Number Decoding Benchmarks

let numberDecodingBenchmarks: @Sendable () -> Void = {

    // MARK: Synthetic arrays

    Benchmark("NumberDecode/IntArray/YYJSON") { benchmark in
        let decoder = YYJSONDecoder()
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! decoder.decode([Int].self, from: intArrayJSON))
        }
    }

    Benchmark("NumberDecode/IntArray/YYJSON-fast") { benchmark in
        var decoder = YYJSONDecoder()
        decoder.numberDecodingStrategy = .fast
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! decoder.decode([Int].self, from: intArrayJSON))
        }
    }

    Benchmark("NumberDecode/IntArray/Foundation") { benchmark in
        let decoder = JSONDecoder()
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! decoder.decode([Int].self, from: intArrayJSON))
        }
    }

    Benchmark("NumberDecode/DoubleArray/YYJSON") { benchmark in
        let decoder = YYJSONDecoder()
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! decoder.decode([Double].self, from: doubleArrayJSON))
        }
    }

    Benchmark("NumberDecode/DoubleArray/YYJSON-fast") { benchmark in
        var decoder = YYJSONDecoder()
        decoder.numberDecodingStrategy = .fast
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! decoder.decode([Double].self, from: doubleArrayJSON))
        }
    }

    Benchmark("NumberDecode/DoubleArray/Foundation") { benchmark in
        let decoder = JSONDecoder()
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! decoder.decode([Double].self, from: doubleArrayJSON))
        }
    }

    Benchmark("NumberDecode/DecimalArray/YYJSON") { benchmark in
        let decoder = YYJSONDecoder()
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! decoder.decode([Decimal].self, from: decimalArrayJSON))
        }
    }

    Benchmark("NumberDecode/DecimalArray/Foundation") { benchmark in
        let decoder = JSONDecoder()
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! decoder.decode([Decimal].self, from: decimalArrayJSON))
        }
    }

    Benchmark("NumberDecode/MixedArray/YYJSON") { benchmark in
        let decoder = YYJSONDecoder()
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! decoder.decode([Mixed].self, from: mixedArrayJSON))
        }
    }

    Benchmark("NumberDecode/MixedArray/YYJSON-fast") { benchmark in
        var decoder = YYJSONDecoder()
        decoder.numberDecodingStrategy = .fast
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! decoder.decode([Mixed].self, from: mixedArrayJSON))
        }
    }

    Benchmark("NumberDecode/MixedArray/Foundation") { benchmark in
        let decoder = JSONDecoder()
        for _ in benchmark.scaledIterations {
            Benchmark.blackHole(try! decoder.decode([Mixed].self, from: mixedArrayJSON))
        }
    }

    // MARK: canada.json coordinate pairs — ~100k pairs (200k Doubles)

    if let data = canadaCoordsJSON {
        Benchmark("NumberDecode/canada.coords/YYJSON") { benchmark in
            let decoder = YYJSONDecoder()
            for _ in benchmark.scaledIterations {
                Benchmark.blackHole(try! decoder.decode([[Double]].self, from: data))
            }
        }

        Benchmark("NumberDecode/canada.coords/YYJSON-fast") { benchmark in
            var decoder = YYJSONDecoder()
            decoder.numberDecodingStrategy = .fast
            for _ in benchmark.scaledIterations {
                Benchmark.blackHole(try! decoder.decode([[Double]].self, from: data))
            }
        }

        Benchmark("NumberDecode/canada.coords/Foundation") { benchmark in
            let decoder = JSONDecoder()
            for _ in benchmark.scaledIterations {
                Benchmark.blackHole(try! decoder.decode([[Double]].self, from: data))
            }
        }
    }
}
