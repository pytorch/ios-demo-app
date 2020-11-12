//
//  ViewController.swift
//  ObjectDetection
//
//  Created by Jeff Tang on 11/11/20.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    
    private lazy var module: TorchModule = {
        if let filePath = Bundle.main.path(forResource: "yolov5s.torchscript_trace", ofType: "pt"),
            let module = TorchModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Can't find the model file!")
        }
    }()

    
    private let classes = ["person", "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck", "boat", "traffic light",
                           "fire hydrant", "stop sign", "parking meter", "bench", "bird", "cat", "dog", "horse", "sheep", "cow",
                           "elephant", "bear", "zebra", "giraffe", "backpack", "umbrella", "handbag", "tie", "suitcase", "frisbee",
                           "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove", "skateboard", "surfboard",
                           "tennis racket", "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl", "banana", "apple",
                           "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza", "donut", "cake", "chair", "couch",
                           "potted plant", "bed", "dining table", "toilet", "tv", "laptop", "mouse", "remote", "keyboard", "cell phone",
                           "microwave", "oven", "toaster", "sink", "refrigerator", "book", "clock", "vase", "scissors", "teddy bear",
                           "hair drier", "toothbrush"]

    // https://github.com/hollance/YOLO-CoreML-MPSNNGraph/blob/master/Common/Helpers.swift
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

    
    override func viewDidLoad() {
        super.viewDidLoad()
        //let image = UIImage(named: "test1.png")!
        let image = UIImage(named: "test2.jpg")!
        //let image = UIImage(named: "test3.png")!

        //let resizedImage = image
        let resizedImage = image.resized(to: CGSize(width: 640, height: 640))

        imageView.image = resizedImage


        guard var pixelBuffer = resizedImage.normalized_no_std_mean() else {
            return
        }
        
        // TODO: put this in a worker queue
        guard let outputs = module.detect(image: UnsafeMutableRawPointer(&pixelBuffer)) else {
            return
        }
        
        // outputs is of size 25200*85, each row starts with left,top,right,bottom,score and 80 class probability (? - sum of 80 values not exactly same as 1.0: sum(prediction[0, 24599][5:]) is 0.7299)
        
        let conf_thres=0.15
        let ratio = Double(imageView.frame.size.width / imageView.image!.size.width)
        let starty = Double((imageView.frame.size.height - (CGFloat(ratio) * imageView.image!.size.height))/2)
        var predictions = [Prediction]()
        for i in 0..<25200 {
            if Double(outputs[i*85+4]) > conf_thres {
                let x = Double(outputs[i*85])
                let y = Double(outputs[i*85+1])
                let w = Double(outputs[i*85+2])
                let h = Double(outputs[i*85+3])
                
                let left = x - w/2
                let top = y - h/2
                let right = x + w/2
                let bottom = y + h/2
                
                var max = Double(outputs[i*85+5])
                // get class index (0-79)
                var cls = 0
                for j in 0..<80 {
                    if Double(outputs[i*85+5+j]) > max {
                        max = Double(outputs[i*85+5+j])
                        cls = j
                    }
                }
                
                
                // draw rect
                // TODO: from inside the worker queue, draw in the main queue
                let rect = CGRect(x: ratio*left, y: starty+ratio*top, width: ratio*(right-left), height: ratio*(bottom-top))
                print(rect)

                let prediction = Prediction(classIndex: cls,
                                            score: Float(outputs[i*85+4]),
                                            rect: rect)
                predictions.append(prediction)
            }
        }
        
        
        let nmsPredictons = nonMaxSuppression(boxes: predictions, limit: 15, threshold: 0.3)
        
        for pred in nmsPredictons {
            let bbox = UIView(frame: pred.rect)
            bbox.backgroundColor = UIColor.clear
            bbox.layer.borderColor = UIColor.purple.cgColor
            bbox.layer.borderWidth = 3
            imageView.addSubview(bbox)
            
            let textLayer = CATextLayer()
            textLayer.string = String(format: " %@ %.2f", classes[pred.classIndex], pred.score)
            textLayer.foregroundColor = UIColor.yellow.cgColor
            textLayer.fontSize = 18
            textLayer.frame = CGRect(x: pred.rect.origin.x, y: pred.rect.origin.y, width:100, height:25)
            imageView.layer.addSublayer(textLayer)
        }

    }


}

