import UIKit

class ObjectDetector: Inferencer {
    private var isRunning: Bool = false
    private lazy var module: TorchModule = {
        if let filePath = Bundle.main.path(forResource: "yolov5s.torchscript", ofType: "pt"),
            let module = TorchModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Failed to load model!")
        }
    }()

    private var labels: [String] = {
        if let filePath = Bundle.main.path(forResource: "words", ofType: "txt"),
            let labels = try? String(contentsOfFile: filePath) {
            return labels.components(separatedBy: .newlines)
        } else {
            fatalError("Label file was not found.")
        }
    }()

//    func predict(_ buffer: [Float32], resultCount: Int) throws -> ([InferenceResult], Double)? {
//        if isRunning {
//            return nil
//        }
//        isRunning = true
//        let startTime = CACurrentMediaTime()
//        var tensorBuffer = buffer;
//        guard let outputs = module.predict(image: UnsafeMutableRawPointer(&tensorBuffer)) else {
//            throw PredictorError.invalidInputTensor
//        }
//        isRunning = false
//        let inferenceTime = (CACurrentMediaTime() - startTime) * 1000
//        let results = topK(scores: outputs, labels: labels, count: resultCount)
//        return (results, inferenceTime)
//    }
    
    
    
}
