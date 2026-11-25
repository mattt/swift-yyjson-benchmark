import Foundation

// Flatten the polygon rings before measuring the decoders.
package func canadaCoordinatePairs(from data: Data) -> Data? {
    struct Collection: Decodable {
        struct Feature: Decodable {
            struct Geometry: Decodable {
                let coordinates: [[[Double]]]
            }
            let geometry: Geometry
        }
        let features: [Feature]
    }

    guard let collection = try? JSONDecoder().decode(Collection.self, from: data) else { return nil }
    var pairs: [[Double]] = []
    pairs.reserveCapacity(120_000)
    for feature in collection.features {
        for ring in feature.geometry.coordinates {
            for point in ring {
                guard point.count == 2 else { return nil }
                pairs.append(point)
            }
        }
    }
    guard !pairs.isEmpty else { return nil }
    return try? JSONSerialization.data(withJSONObject: pairs)
}
