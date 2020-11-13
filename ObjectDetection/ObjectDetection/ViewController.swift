import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var btnRun: UIButton!
    @IBOutlet weak var btnNext: UIButton!
    
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

    private let classes = ["person", "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck", "boat", "traffic light", "fire hydrant", "stop sign", "parking meter", "bench", "bird", "cat", "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra", "giraffe", "backpack", "umbrella", "handbag", "tie", "suitcase", "frisbee", "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove", "skateboard", "surfboard", "tennis racket", "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl", "banana", "apple", "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza", "donut", "cake", "chair", "couch", "potted plant", "bed", "dining table", "toilet", "tv", "laptop", "mouse", "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "sink", "refrigerator", "book", "clock", "vase", "scissors", "teddy bear","hair drier", "toothbrush"]

    
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: imageName)!
        imageView.image = image
        
        btnRun.setTitle("Detect", for: .normal)
    }

    @IBAction func runTapped(_ sender: Any) {
        btnRun.isEnabled = false
        btnRun.setTitle("Running the model...", for: .normal)

        // 640x640 is the img-size used when exporting the model
        let resizedImage = image!.resized(to: CGSize(width: 640, height: 640))
        
        let imgScaleX : Double = Double(image!.size.width / 640);
        let imgScaleY : Double = Double(image!.size.height / 640);
        
        let thhreshold = 0.35
        
        let ivScaleX : Double = (image!.size.width > image!.size.height ? Double(imageView.frame.size.width / imageView.image!.size.width) : Double(imageView.image!.size.width / imageView.image!.size.height))
        let ivScaleY : Double = (image!.size.height > image!.size.width ? Double(imageView.frame.size.height / imageView.image!.size.height) : Double(imageView.image!.size.height / imageView.image!.size.width))

        let startX = Double((imageView.frame.size.width - CGFloat(ivScaleX) * imageView.image!.size.width)/2)
        let startY = Double((imageView.frame.size.height -  CGFloat(ivScaleY) * imageView.image!.size.height)/2)

        guard var pixelBuffer = resizedImage.normalized() else {
            return
        }
        
        DispatchQueue.global().async {
            guard let outputs = self.module.detect(image: UnsafeMutableRawPointer(&pixelBuffer)) else {
                return
            }
            
            // outputs is of size 25200*85, each row starts with left,top,right,bottom,score and 80 class probability (? - sum of 80 values not exactly same as 1.0: sum(prediction[0, 24599][5:]) is 0.7299)
            
            var predictions = [Prediction]()
            for i in 0..<25200 {
                if Double(outputs[i*85+4]) > thhreshold {
                    let x = Double(outputs[i*85])
                    let y = Double(outputs[i*85+1])
                    let w = Double(outputs[i*85+2])
                    let h = Double(outputs[i*85+3])
                    
                    let left = imgScaleX * (x - w/2)
                    let top = imgScaleY * (y - h/2)
                    let right = imgScaleX * (x + w/2)
                    let bottom = imgScaleY * (y + h/2)
                    
                    var max = Double(outputs[i*85+5])
                    // get class index (0-79)
                    var cls = 0
                    for j in 0..<80 {
                        if Double(outputs[i*85+5+j]) > max {
                            max = Double(outputs[i*85+5+j])
                            cls = j
                        }
                    }
  
                    let rect = CGRect(x: startX+ivScaleX*left, y: startY+top*ivScaleY, width: ivScaleX*(right-left), height: ivScaleY*(bottom-top))
                    
                    let prediction = Prediction(classIndex: cls, score: Float(outputs[i*85+4]), rect: rect)
                    predictions.append(prediction)
                }
            }
            
            let nmsPredictons = self.nonMaxSuppression(boxes: predictions, limit: 15, threshold: 0.3)
            
            DispatchQueue.main.async {
                for pred in nmsPredictons {
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

    private func cleanDrawing() {
        if let layers = imageView.layer.sublayers {
            for layer in layers {
                if layer is CATextLayer {
                    layer.removeFromSuperlayer()
                }
            }
            for view in imageView.subviews {
                view.removeFromSuperview()
            }
        }
    }
    
    @IBAction func nextTapped(_ sender: Any) {
        cleanDrawing()
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
        cleanDrawing()
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self;
        imagePickerController.sourceType = .photoLibrary
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func cameraTapped(_ sender: Any) {
        cleanDrawing()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self;
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        imageView.image = image
        self.dismiss(animated: true, completion: nil)
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // code below about NMS is from  https://github.com/hollance/YOLO-CoreML-MPSNNGraph/blob/master/Common/Helpers.swift
    /**
      Removes bounding boxes that overlap too much with other boxes that have
      a higher score.
      - Parameters:
        - boxes: an array of bounding boxes and their scores
        - limit: the maximum number of boxes that will be selected
        - threshold: used to decide whether boxes overlap too much
    */
    struct Prediction {
      let classIndex: Int
      let score: Float
      let rect: CGRect
    }
    func nonMaxSuppression(boxes: [Prediction], limit: Int, threshold: Float) -> [Prediction] {

      // Do an argsort on the confidence scores, from high to low.
      let sortedIndices = boxes.indices.sorted { boxes[$0].score > boxes[$1].score }

      var selected: [Prediction] = []
      var active = [Bool](repeating: true, count: boxes.count)
      var numActive = active.count

      // The algorithm is simple: Start with the box that has the highest score.
      // Remove any remaining boxes that overlap it more than the given threshold
      // amount. If there are any boxes left (i.e. these did not overlap with any
      // previous boxes), then repeat this procedure, until no more boxes remain
      // or the limit has been reached.
      outer: for i in 0..<boxes.count {
        if active[i] {
          let boxA = boxes[sortedIndices[i]]
          selected.append(boxA)
          if selected.count >= limit { break }

          for j in i+1..<boxes.count {
            if active[j] {
              let boxB = boxes[sortedIndices[j]]
              if IOU(a: boxA.rect, b: boxB.rect) > threshold {
                active[j] = false
                numActive -= 1
                if numActive <= 0 { break outer }
              }
            }
          }
        }
      }
      return selected
    }
    
    /**
      Computes intersection-over-union overlap between two bounding boxes.
    */
    public func IOU(a: CGRect, b: CGRect) -> Float {
      let areaA = a.width * a.height
      if areaA <= 0 { return 0 }

      let areaB = b.width * b.height
      if areaB <= 0 { return 0 }

      let intersectionMinX = max(a.minX, b.minX)
      let intersectionMinY = max(a.minY, b.minY)
      let intersectionMaxX = min(a.maxX, b.maxX)
      let intersectionMaxY = min(a.maxY, b.maxY)
      let intersectionArea = max(intersectionMaxY - intersectionMinY, 0) *
                             max(intersectionMaxX - intersectionMinX, 0)
      return Float(intersectionArea / (areaA + areaB - intersectionArea))
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
}

