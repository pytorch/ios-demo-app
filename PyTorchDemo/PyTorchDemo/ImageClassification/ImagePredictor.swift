import UIKit

class ImagePredictor: Predictor {
  private var isRunning: Bool = false

  private lazy var module: VisionTorchModule = {
    guard let filePath = Bundle.main.path(forResource: "mobilenet_quantized2", ofType: "pt"),
       let module = VisionTorchModule(fileAtPath: filePath)
    else {
      fatalError("Failed to load model!")
    }
    return module
  }()

  private var labels: [String] = {
    guard let filePath = Bundle.main.path(forResource: "words", ofType: "txt"),
          let labels = try? String(contentsOfFile: filePath)
    else {
      fatalError("Label file was not found.")
    }
    return labels.split(whereSeparator: \.isNewline).map { .init($0) }
  }()

  func predict(_ buffer: [Float32], resultCount: Int) throws -> ([InferenceResult], Double)? {
    guard !isRunning else { return nil }
    isRunning = true
    defer { isRunning = false }

    var tmp = buffer
    return tmp.withUnsafeMutableBufferPointer { ptr in
      let startTime = CACurrentMediaTime()
      if let output = module.predict(image: &(ptr.baseAddress!.pointee)) {
        let duration = (CACurrentMediaTime() - startTime) * 1000
        let bufferPointer = UnsafeBufferPointer(start: output, count: labels.count)
        return (topK(scores: bufferPointer, labels: labels, count: 3), duration)
      }
      return nil
    }
  }
}
