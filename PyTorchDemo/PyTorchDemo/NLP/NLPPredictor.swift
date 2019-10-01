import UIKit

class NLPPredictor: Predictor {
    private var module: NLPTorchModule = {
        if let filePath = Bundle.main.path(forResource: "reddit", ofType: "pt"),
            let module = NLPTorchModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Can't find the model with the given path!")
        }
    }()

    private var topics: [String] = []
    private var isRunning: Bool = false

    init() {
        topics = loadTopics()
    }

    func forward(_ text: String, resultCount: Int, completionHandler: ([InferenceResult]?, Error?) -> Void) {
        if text.isEmpty {
            return
        }
        if isRunning {
            return
        }
        isRunning = true
        guard let outputs = module.predict(text: text) else {
            completionHandler([], PredictorError.invalidInputTensor)
            return
        }
        let results = topK(scores: outputs, labels: topics, count: resultCount)
        completionHandler(results, nil)
        isRunning = false
    }

    private func loadTopics() -> [String] {
        guard let topics = module.topics() else {
            fatalError("Load reddit topics failed!")
        }
        return topics
    }
}
