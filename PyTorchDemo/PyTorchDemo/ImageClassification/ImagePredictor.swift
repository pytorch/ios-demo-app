import UIKit

class ImagePredictor: Predictor {
    var isRunning: Bool = false
    var module: VisionTorchModule?
    var labels: [String] = []

    init() {
        module = loadModel(name: "mobilenet_quantized")
        labels = loadLabels(name: "words")
    }

    func forward(_ buffer: [Float32]?, resultCount: Int, completionHandler: ([InferenceResult]?, Double, Error?) -> Void) {
        guard var tensorBuffer = buffer else {
            return
        }
        if isRunning {
            return
        }
        isRunning = true
        let startTime = CFAbsoluteTimeGetCurrent()
        guard let outputs = module?.predict(image: UnsafeMutableRawPointer(&tensorBuffer)) else {
            completionHandler([], 0.0, PredictorError.invalidInputTensor)
            return
        }
        let inferenceTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        let results = topK(scores: outputs, labels: labels, count: resultCount, inferenceTime: inferenceTime)
        completionHandler(results, inferenceTime, nil)
        isRunning = false
    }

    private func loadLabels(name: String) -> [String] {
        if let filePath = Bundle.main.path(forResource: name, ofType: "txt"),
            let labels = try? String(contentsOfFile: filePath) {
            return labels.components(separatedBy: .newlines)
        } else {
            fatalError("Label file was not found.")
        }
    }

    private func loadModel(name: String) -> VisionTorchModule? {
        if let filePath = Bundle.main.path(forResource: name, ofType: "pt"),
            let module = VisionTorchModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Can't find the model with the given path!")
        }
    }
}
