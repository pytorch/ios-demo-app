import AVFoundation
import UIKit

class LiveObjectDetectionViewController: ViewController {
    @IBOutlet var cameraView: CameraPreviewView!
    @IBOutlet var benchmarkLabel: UILabel!
    @IBOutlet var indicator: UIActivityIndicatorView!
    //private var predictor = ImagePredictor()
    private var cameraController = CameraController()
    private let delayMs: Double = 500
    private var prevTimestampMs: Double = 0.0
    
    
    private lazy var module: TorchModule = {
        if let filePath = Bundle.main.path(forResource: "yolov5s.torchscript", ofType: "pt"),
            let module = TorchModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Can't find the model file!")
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        //bottomView.config(resultCount: 3)
        cameraController.configPreviewLayer(cameraView)
        cameraController.videoCaptureCompletionBlock = { [weak self] buffer, error in
            guard let strongSelf = self else { return }
            if error != nil {
                //strongSelf.showAlert(error)
                return
            }
            guard var pixelBuffer = buffer else { return }
            
            let currentTimestamp = CACurrentMediaTime()
            if (currentTimestamp - strongSelf.prevTimestampMs) * 1000 <= strongSelf.delayMs { return }
            strongSelf.prevTimestampMs = currentTimestamp
            
            DispatchQueue.global().async {
                let startTime = CACurrentMediaTime()
                guard let outputs = self?.module.detect(image: UnsafeMutableRawPointer(&pixelBuffer)) else {
                    return
                }
                
                var predictions = [Prediction]()
                for i in 0..<25200 {
                    if Double(outputs[i*85+4]) > 0.35 {
                        let x = Double(outputs[i*85])
                        let y = Double(outputs[i*85+1])
                        let w = Double(outputs[i*85+2])
                        let h = Double(outputs[i*85+3])
                        
                        let imgScaleX = 1.0
                        let imgScaleY = 1.0
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
      
                        let startX = 0.0
                        let startY = 0.0
                        let ivScaleX = 1.0
                        let ivScaleY = 1.0
                        let rect = CGRect(x: startX+ivScaleX*left, y: startY+top*ivScaleY, width: ivScaleX*(right-left), height: ivScaleY*(bottom-top))
                        
                        let prediction = Prediction(classIndex: cls, score: Float(outputs[i*85+4]), rect: rect)
                        predictions.append(prediction)
                    }
                }
                
                let nmsPredictons = nonMaxSuppression(boxes: predictions, limit: 15, threshold: 0.3)

                print(nmsPredictons)
                
                
            
            
//            if let results = try? strongSelf.predictor.predict(pixelBuffer, resultCount: 3) {
                DispatchQueue.main.async {
                    strongSelf.indicator.isHidden = true
//                    strongSelf.bottomView.isHidden = false
                    strongSelf.benchmarkLabel.isHidden = false
//                    strongSelf.benchmarkLabel.text = String(format: "%.2fms", results.1)
                    strongSelf.benchmarkLabel.text = String(format: "%.2fms", CACurrentMediaTime() - startTime)
//                    strongSelf.bottomView.update(results: results.0)
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        cameraController.startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraController.stopSession()
    }


    @IBAction func onBackClicked(_: Any) {
        navigationController?.popViewController(animated: true)
    }
}
