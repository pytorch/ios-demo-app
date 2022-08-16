import UIKit

class ImagePredictor: Predictor {
    private var isRunning: Bool = false
    private lazy var module: VisionTorchModule = {
        if let filePath = Bundle.main.path(forResource: "mobilenet_quantized", ofType: "pt"),
            let module = VisionTorchModule(fileAtPath: filePath) {
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

    func predict(_ buffer: [Float32], resultCount: Int) throws -> ([InferenceResult], Double)? {
        if isRunning {
            return nil
        }
        isRunning = true

        // UnsafeMutablePointer() doesn't guarantee that the converted pointer points to the memory that is still being allocated
        // So we create a new pointer and copy the &pixelBuffer's memory to where it points to
        let copiedBufferPtr = UnsafeMutablePointer<Float>.allocate(capacity: buffer.count)
        copiedBufferPtr.initialize(from: buffer, count: buffer.count)

        let startTime = CACurrentMediaTime()
        guard let outputs = module.predict(image: copiedBufferPtr) else {
            copiedBufferPtr.deallocate()
            throw PredictorError.invalidInputTensor
        }
        copiedBufferPtr.deallocate()
        isRunning = false
        let inferenceTime = (CACurrentMediaTime() - startTime) * 1000
        let results = topK(scores: outputs, labels: labels, count: resultCount)
        return (results, inferenceTime)
    }
}
