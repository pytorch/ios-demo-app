import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var btnSegment: UIButton!
    
    private var imageName = "deeplab.jpg"
    private var image : UIImage?
    private let imageHelper = UIImageHelper()

    private lazy var module: TorchModule = {
        if let filePath = Bundle.main.path(forResource:
            "deeplabv3_scripted", ofType: "pt"),
            let module = TorchModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Can't find the model file!")
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        btnSegment.setTitle("Segment", for: .normal)
        image = UIImage(named: imageName)!
        imageView.image = image
    }

    @IBAction func doInfer(_ sender: Any) {
        btnSegment.isEnabled = false
        btnSegment.setTitle("Running the model...", for: .normal)
        let resizedImage = image!.resized(to: CGSize(width: 250, height: 250))
        guard var pixelBuffer = resizedImage.normalized() else {
            return
        }
                
        let w = Int32(resizedImage.size.width)
        let h = Int32(resizedImage.size.height)
        DispatchQueue.global().async {
            let copiedBufferPtr = UnsafeMutablePointer<Float>.allocate(capacity: pixelBuffer.count)
            copiedBufferPtr.initialize(from: pixelBuffer, count: pixelBuffer.count)
            let buffer = self.module.segment(image: copiedBufferPtr, withWidth:w, withHeight: h)
            copiedBufferPtr.deallocate()
            
            let copiedOutputBufferPtr = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: Int(w * h * 3))
            copiedOutputBufferPtr.initialize(from: buffer, count: Int(w * h * 3))
            
            DispatchQueue.main.async {
                self.imageView.image = self.imageHelper.convertRGBBuffer(toUIImage: copiedOutputBufferPtr , withWidth: w, withHeight: h)
                self.btnSegment.isEnabled = true
                self.btnSegment.setTitle("Segment", for: .normal)
            }
        }
    }
    
    @IBAction func doRestart(_ sender: Any) {
        if imageName == "deeplab.jpg" {
            imageName = "dog.jpg"
        }
        else {
            imageName = "deeplab.jpg"
        }
        image = UIImage(named: imageName)!
        imageView.image = image
    }    
}

