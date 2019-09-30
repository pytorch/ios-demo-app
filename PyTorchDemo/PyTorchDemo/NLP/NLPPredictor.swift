import UIKit

class NLPPredictor: Predictor {
    var module: NLPTorchModule?
    var topics: [String] = []
    var isRunning: Bool = false

    init() {
        module = loadModel(name: "reddit")
        topics = loadTopics()
    }

    func forward(_ text: String, resultCount: Int, completionHandler: ([InferenceResult]?, Double, Error?) -> Void) {
        if isRunning {
            return
        }
        isRunning = true
        let startTime = CFAbsoluteTimeGetCurrent()
        guard let outputs = module?.predict(text: text) else {
            completionHandler([], 0.0, PredictorError.invalidInputTensor)
            return
        }
        let inferenceTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        let results = topK(scores: outputs, labels: topics, count: resultCount, inferenceTime: inferenceTime)
        completionHandler(results, inferenceTime, nil)
        isRunning = false
    }

    private func loadModel(name: String) -> NLPTorchModule? {
        if let filePath = Bundle.main.path(forResource: name, ofType: "pt"),
            let module = NLPTorchModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Can't find the model with the given path!")
        }
    }

    private func loadTopics() -> [String] {
        guard let topics = module?.topics() else {
            fatalError("Load topics failed!")
        }
        return topics
    }
}
