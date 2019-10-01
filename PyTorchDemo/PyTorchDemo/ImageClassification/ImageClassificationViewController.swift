import AVFoundation
import UIKit

class ImageClassificationViewController: ViewController {
    @IBOutlet var cameraView: CameraPreviewView!
    @IBOutlet var bottomView: ImageClassificationResultView!
    @IBOutlet var benchmarkLabel: UILabel!
    @IBOutlet var indicator: UIActivityIndicatorView!
    private var predictor = ImagePredictor()
    private var cameraController = CameraController()
    private let delayMs: Double = 500
    private var prevTimestampMs: Double = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        bottomView.config(resultCount: 3)
        cameraController.configPreviewLayer(cameraView)
        cameraController.videoCaptureCompletionBlock = { [weak self] buffer, error in
            guard let strongSelf = self else { return }
            if error != nil {
                strongSelf.showAlert(error)
                return
            }
            let currentTimestamp = CACurrentMediaTime()
            if (currentTimestamp - strongSelf.prevTimestampMs) * 1000 <= strongSelf.delayMs { return }
            strongSelf.prevTimestampMs = currentTimestamp
            if let results = try? strongSelf.predictor.forward(buffer, resultCount: 3) {
                DispatchQueue.main.async { strongSelf.indicator.isHidden = true
                    strongSelf.bottomView.isHidden = false
                    strongSelf.benchmarkLabel.isHidden = false
                    strongSelf.benchmarkLabel.text = String(format: "%.2fms", results.1)
                    strongSelf.bottomView.update(results: results.0)
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

    @IBAction func onInfoBtnClicked(_: Any) {
        VisionModelCard.show()
    }

    @IBAction func onBackClicked(_: Any) {
        navigationController?.popViewController(animated: true)
    }
}
