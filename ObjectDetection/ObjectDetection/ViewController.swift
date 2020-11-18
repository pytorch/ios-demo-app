import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var btnRun: UIButton!
    @IBOutlet weak var btnNext: UIButton!
    
    // 640x640 is the img-size used when exporting the model
    private let width : Double = 640.0
    private let height : Double = 640.0
    private let thhreshold = 0.35
    private let testImages = ["test1.png", "test2.jpg", "test3.png"]
    
    private var imageName = "test1.png"

    private var image : UIImage?

    private lazy var module: TorchModule = {
        if let filePath = Bundle.main.path(forResource: "yolov5s.torchscript", ofType: "pt"),
            let module = TorchModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Can't find the model file!")
        }
    }()
    
    private var classes: [String] = {
        if let filePath = Bundle.main.path(forResource: "classes", ofType: "txt"),
            let classes = try? String(contentsOfFile: filePath) {
            return classes.components(separatedBy: .newlines)
        } else {
            fatalError("classes file was not found.")
        }
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: imageName)!
        if let iv = imageView {
            iv.image = image
            
            btnRun.setTitle("Detect", for: .normal)
        }
    }

    @IBAction func runTapped(_ sender: Any) {
        btnRun.isEnabled = false
        btnRun.setTitle("Running the model...", for: .normal)


        let resizedImage = image!.resized(to: CGSize(width: width, height: height))
        
        let imgScaleX : Double = Double(image!.size.width) / width;
        let imgScaleY : Double = Double(image!.size.height) / height;
        
        let ivScaleX : Double = (image!.size.width > image!.size.height ? Double(imageView.frame.size.width / imageView.image!.size.width) : Double(imageView.image!.size.width / imageView.image!.size.height))
        let ivScaleY : Double = (image!.size.height > image!.size.width ? Double(imageView.frame.size.height / imageView.image!.size.height) : Double(imageView.image!.size.height / imageView.image!.size.width))

        let startX = Double((imageView.frame.size.width - CGFloat(ivScaleX) * imageView.image!.size.width)/2)
        let startY = Double((imageView.frame.size.height -  CGFloat(ivScaleY) * imageView.image!.size.height)/2)

        guard var pixelBuffer = resizedImage.normalized() else {
            return
        }
        
        DispatchQueue.global().async {
            let currTime = CACurrentMediaTime()
            guard let outputs = self.module.detect(image: UnsafeMutableRawPointer(&pixelBuffer)) else {
                return
            }
            let newTime = CACurrentMediaTime()
            print(currTime, newTime, newTime-currTime)
            
            let nmsPredictions = outputsToNMSPredictions(outputs: outputs, imgScaleX: imgScaleX, imgScaleY: imgScaleY, ivScaleX: ivScaleX, ivScaleY: ivScaleY, startX: startX, startY: startY)
            
            DispatchQueue.main.async {
                for pred in nmsPredictions {
                    let bbox = UIView(frame: pred.rect)
                    bbox.backgroundColor = UIColor.clear
                    bbox.layer.borderColor = UIColor.purple.cgColor
                    bbox.layer.borderWidth = 3
                    self.imageView.addSubview(bbox)
                    
                    let textLayer = CATextLayer()
                    textLayer.string = String(format: " %@ %.2f", self.classes[pred.classIndex], pred.score)
                    textLayer.foregroundColor = UIColor.red.cgColor
                    textLayer.fontSize = 18
                    textLayer.frame = CGRect(x: pred.rect.origin.x, y: pred.rect.origin.y, width:100, height:25)
                    self.imageView.layer.addSublayer(textLayer)
                }
                self.btnRun.isEnabled = true
                self.btnRun.setTitle("Detect", for: .normal)
            }
        }
    }

    
    @IBAction func nextTapped(_ sender: Any) {
        cleanDrawing(imageView: imageView)
        if imageName == "test1.png" {
            imageName = "test2.jpg"
            btnNext.setTitle("Text Image 2/3", for: .normal)
        }
        else if imageName == "test2.jpg" {
            imageName = "test3.png"
            btnNext.setTitle("Text Image 3/3", for: .normal)
        }
        else {
            imageName = "test1.png"
            btnNext.setTitle("Text Image 1/3", for: .normal)
        }
        image = UIImage(named: imageName)!
        imageView.image = image
    }

    @IBAction func photosTapped(_ sender: Any) {
        cleanDrawing(imageView: imageView)
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self;
        imagePickerController.sourceType = .photoLibrary
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func cameraTapped(_ sender: Any) {
        cleanDrawing(imageView: imageView)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self;
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        image = image!.resized(to: CGSize(width: 640, height: 640*image!.size.height/image!.size.width))
        imageView.image = image
        self.dismiss(animated: true, completion: nil)
    }
}


