import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    var imageName = "deeplab.jpg"
    var image : UIImage? = nil
    
    private var imageHelper: UIImageHelper  = UIImageHelper()

    
    override func viewDidLoad() {
        super.viewDidLoad()

        image = UIImage(named: imageName)!
        imageView.image = image
    }

    private lazy var module: TorchModule = {
        if let filePath = Bundle.main.path(forResource:
            "deeplabv3_scripted", ofType: "pt"),
            let module = TorchModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Can't find the model file!")
        }
    }()
    

    @IBAction func doInfer(_ sender: Any) {
        guard var pixelBuffer = image!.normalized() else {
            return
        }
        
        let buffer = module.predict(image: UnsafeMutableRawPointer(&pixelBuffer))
        let width = Int32(image!.size.width)
        let height = Int32(image!.size.height)
        imageView.image = imageHelper.convertRGBBuffer(toUIImage: buffer , withWidth: width, withHeight: height)
    }

    
    @IBAction func doRestart(_ sender: Any) {
        image = UIImage(named: imageName)!
        imageView.image = image
    }
    
}

