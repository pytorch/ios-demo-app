import Foundation

struct InferenceResult {
    let score: Float
    let label: String
}

enum InferencerError: Swift.Error {
    case invalidModel
    case invalidInputTensor
    case invalidOutputTensor
}

protocol Inferencer {}

extension Inferencer {
    func topK(scores: [NSNumber], labels: [String], count: Int) -> [InferenceResult] {
        let zippedResults = zip(labels.indices, scores)
        let sortedResults = zippedResults.sorted { $0.1.floatValue > $1.1.floatValue }.prefix(count)
        return sortedResults.map { InferenceResult(score: $0.1.floatValue, label: labels[$0.0]) }
    }
}
