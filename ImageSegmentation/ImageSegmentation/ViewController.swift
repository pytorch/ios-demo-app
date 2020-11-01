import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    
    private let image = UIImage(named: "deeplab.jpg")
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

        imageView.image = image
    }

    @IBAction func doInfer(_ sender: Any) {
        guard var pixelBuffer = image!.normalized() else {
            return
        }
                
        if let img = image {
            let w = Int32(img.size.width)
            let h = Int32(img.size.height)
            DispatchQueue.global().async {
                let buffer = self.module.segment(image: UnsafeMutableRawPointer(&pixelBuffer), withWidth:w, withHeight: h)
                DispatchQueue.main.async {
                    self.imageView.image = self.imageHelper.convertRGBBuffer(toUIImage: buffer , withWidth: w, withHeight: h)
                }
            }
        }
    }
    
    @IBAction func doRestart(_ sender: Any) {
        imageView.image = image
    }    
}

