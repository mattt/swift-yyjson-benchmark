# swift-yyjson-benchmark

Benchmarks for [swift-yyjson](https://github.com/mattt/swift-yyjson),
comparing performance against Foundation's JSON APIs.

## Prerequisites

- Swift 6.1+
- macOS 26+

## Setup

Download the JSON test fixtures:

```bash
make fixtures
```

This downloads standard JSON benchmark files from
[nativejson-benchmark](https://github.com/miloyip/nativejson-benchmark):

- `twitter.json` (~632KB) - Twitter API response with nested objects and CJK text
- `citm_catalog.json` (~1.7MB) - Large catalog with many string keys
- `canada.json` (~2.2MB) - GeoJSON with many floating-point coordinates
- `tokenizer.json` (~11MB) - HuggingFace tokenizer ([mlx-community/Qwen3-0.6B-Base-DQ5](https://huggingface.co/mlx-community/Qwen3-0.6B-Base-DQ5)) with large vocab and merges arrays

## Running Benchmarks

Run all benchmarks:

```bash
swift package benchmark
```

Run specific benchmark groups:

```bash
# Encoder/Decoder comparisons
swift package benchmark run --filter "Encoder"
swift package benchmark run --filter "Decoder"

# Serialization API comparisons
swift package benchmark run --filter "Serialization"

# Real-world fixture benchmarks
swift package benchmark run --filter "Fixture"

# Direct Value API benchmarks
swift package benchmark run --filter "Value"
```

List all available benchmarks:

```bash
swift package benchmark list
```

## Benchmark Categories

### Encoder/Decoder Benchmarks

Compares `YYJSONEncoder`/`YYJSONDecoder` against Foundation's `JSONEncoder`/`JSONDecoder` using the `Codable` protocol.

- **Simple**: Small struct with basic types (string, int, double, bool)
- **Nested**: Struct with nested objects, arrays, and dictionaries
- **Large**: Deeply nested structure with multiple levels

### Serialization Benchmarks

Compares `YYJSONSerialization` against `JSONSerialization` for reading/writing untyped JSON (`[String: Any]`).

### Value API Benchmarks

Benchmarks for `YYJSONValue` direct parsing and access:

- Parsing JSON to value representation
- Key/index-based access
- Object/array iteration
- Deep nested traversal

### Fixture Benchmarks

Real-world JSON files commonly used in JSON parser benchmarks.

## Baseline Comparisons

Save a baseline:

```bash
swift package --allow-writing-to-package-directory benchmark baseline update default
```

Compare against baseline:

```bash
swift package benchmark baseline compare default
```

## Makefile Commands

```bash
make fixtures        # Download test fixtures
make clean           # Remove fixtures
make benchmark       # Download fixtures and run benchmarks
```
