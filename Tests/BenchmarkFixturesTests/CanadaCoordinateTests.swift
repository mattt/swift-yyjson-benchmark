import BenchmarkFixtures
import Foundation
import Testing

@Test func preservesCoordinatePairsInOrder() throws {
    let data = Data("""
        {"features":[
            {"geometry":{"coordinates":[[[1,2],[3,4]],[[5,6]]]}},
            {"geometry":{"coordinates":[[[-7.5,8]]]}}
        ]}
        """.utf8)
    let payload = try #require(canadaCoordinatePairs(from: data))
    let pairs = try JSONDecoder().decode([[Double]].self, from: payload)
    #expect(pairs == [[1, 2], [3, 4], [5, 6], [-7.5, 8]])
}

@Test(arguments: [
    #"{"features":[{"geometry":{"coordinates":[[[1,2],[3]]]}}]}"#,
    #"{"features":[{"geometry":{"coordinates":[[[1,2]]]}},{}]}"#,
    #"{"features":[{"geometry":{"coordinates":[[[true,2]]]}}]}"#,
    #"{"features":[]}"#,
])
func rejectsIncompleteCoordinatePayloads(json: String) {
    #expect(canadaCoordinatePairs(from: Data(json.utf8)) == nil)
}
