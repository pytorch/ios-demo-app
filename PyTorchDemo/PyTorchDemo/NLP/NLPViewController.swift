import UIKit

class NLPViewController: UIViewController {
    @IBOutlet var textView: UITextView!
    @IBOutlet var resultView: NLPResultView!
    var predictor = NLPPredictor()
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        resultView.config(resultCount: 3)
    }

    @IBAction func onInfoClicked(_: Any) {
        textView.resignFirstResponder()
        NLPModelCard.show()
    }

    @IBAction func onBackClicked(_: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension NLPViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn _: NSRange, replacementText text: String) -> Bool {
        if text != "\n" {
            return true
        }
        resultView.isHidden = true
        textView.resignFirstResponder()
        let content = textView.text!
        DispatchQueue.global().async {
            self.predictor.forward(content, resultCount: 3, completionHandler: { results, _, error in
                DispatchQueue.main.async {
                    if error != nil {
                        self.showAlert(error)
                        return
                    }
                    if let results = results {
                        self.resultView.isHidden = false
                        self.resultView.update(results: results)
                    }
                }
            })
        }
        return false
    }
}
