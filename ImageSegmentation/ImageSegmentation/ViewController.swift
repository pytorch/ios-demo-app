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
        
        imageView.image = imageHelper.convertRGBBuffer(toUIImage: buffer , withWidth: 179, withHeight: 179)
    }

    
    @IBAction func doRestart(_ sender: Any) {
        if imageName == "deeplab.jpg" {
            imageName = "kitten.jpg"
        }
        else {
            imageName = "deeplab.jpg"
        }
        image = UIImage(named: imageName)!
        imageView.image = image
    }
    
}

