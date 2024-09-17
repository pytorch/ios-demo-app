import Foundation

struct InferenceResult {
    let score: Float
    let label: String
}

enum PredictorError: Swift.Error {
    case invalidModel
    case invalidInputTensor
    case invalidOutputTensor
}

protocol Predictor {}

extension Predictor {
  func topK(scores: UnsafeBufferPointer<Float>, labels: [String], count: Int) -> [InferenceResult] {
    let zippedResults = zip(scores, labels.indices)
    let sortedResults = zippedResults.sorted { $0.0 > $1.0 }.prefix(count)
    return sortedResults.map { InferenceResult(score: $0.0, label: labels[$0.1]) }
  }
}
