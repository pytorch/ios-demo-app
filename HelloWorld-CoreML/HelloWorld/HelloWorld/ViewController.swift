import UIKit

class ViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var resultView: UITextView!
    private lazy var module: TorchModule = {
        if let filePath = Bundle.main.path(forResource: "mobilenetv2_coreml", ofType: "ptl"),
            let module = TorchModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Can't find the model file!")
        }
    }()

    private lazy var labels: [String] = {
        if let filePath = Bundle.main.path(forResource: "words", ofType: "txt"),
            let labels = try? String(contentsOfFile: filePath) {
            return labels.components(separatedBy: .newlines)
        } else {
            fatalError("Can't find the text file!")
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        let image = UIImage(named: "image.png")!
        imageView.image = image
        let resizedImage = image.resized(to: CGSize(width: 224, height: 224))
        guard let pixelBuffer = resizedImage.normalized() else {
            return
        }
        // UnsafeMutablePointer() doesn't guarantee that the converted pointer points to the memory that is still being allocated
        // So we create a new pointer and copy the &pixelBuffer's memory to where it points to
        let copiedBufferPtr = UnsafeMutablePointer<Float>.allocate(capacity: pixelBuffer.count)
        copiedBufferPtr.initialize(from: pixelBuffer, count: pixelBuffer.count)
        guard let outputs = module.predict(image: copiedBufferPtr) else {
            copiedBufferPtr.deallocate()
            return
        }
        copiedBufferPtr.deallocate()
        let zippedResults = zip(labels.indices, outputs)
        let sortedResults = zippedResults.sorted { $0.1.floatValue > $1.1.floatValue }.prefix(3)
        var text = ""
        for result in sortedResults {
            text += "\u{2022} \(labels[result.0]) \n\n"
        }
        resultView.text = text
    }
}
