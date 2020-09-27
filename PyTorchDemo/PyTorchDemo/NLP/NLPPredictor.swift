import UIKit

class NLPPredictor: Predictor {
    private var module: NLPTorchModule = {
        if let filePath = Bundle.main.path(forResource: "reddit", ofType: "pt"),
            let module = NLPTorchModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Failed to load model!")
        }
    }()

//    private var topics: [String] = []
//    init() {
//        topics = loadTopics()
//    }

//    func predict(_ text: String, resultCount: Int) throws -> [InferenceResult]? {
//        if text.isEmpty {
//            throw PredictorError.invalidInputTensor
//        }
//        guard let outputs = module.predict(text: text) else {
//            throw PredictorError.invalidInputTensor
//        }
//        return topK(scores: outputs, labels: topics, count: resultCount)
//    }

//    private func loadTopics() -> [String] {
//        guard let topics = module.topics() else {
//            fatalError("Failed to load topics from model")
//        }
//        return topics
//    }
}
