import AVFoundation
import UIKit

class ImageClassificationViewController: ViewController {
    @IBOutlet var cameraView: CameraPreviewView!
    @IBOutlet var bottomView: ImageClassificationResultView!
    @IBOutlet var benchmarkLabel: UILabel!
    @IBOutlet var indicator: UIActivityIndicatorView!
    var predictor = ImagePredictor()
    var cameraController = CameraController()

    override func viewDidLoad() {
        super.viewDidLoad()
        bottomView.config(resultCount: 3)
        cameraController.configPreviewLayer(cameraView)
        cameraController.videoCaptureCompletionBlock = { [weak self] buffer, error in
            guard let strongSelf = self else {
                return
            }
            DispatchQueue.main.async {
                if error != nil {
                    strongSelf.showAlert(error)
                    return
                }
            }
            strongSelf.predictor.forward(buffer, resultCount: 3, completionHandler: { results, inferenceTime, error in
                DispatchQueue.main.async {
                    strongSelf.indicator.isHidden = true
                    if error != nil {
                        strongSelf.showAlert(error)
                        return
                    }
                    strongSelf.bottomView.isHidden = false
                    strongSelf.benchmarkLabel.isHidden = false
                    if let results = results {
                        strongSelf.benchmarkLabel.text = String(format: "%.3fms", inferenceTime)
                        strongSelf.bottomView.update(results: results)
                    }
                }
            })
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

    @IBAction func onInfoBtnClicked(_: Any) {
        VisionModelCard.show()
    }

    @IBAction func onBackClicked(_: Any) {
        navigationController?.popViewController(animated: true)
    }
}
