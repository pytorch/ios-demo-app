import UIKit

class NLPViewController: UIViewController {
    @IBOutlet var textView: UITextView!
    @IBOutlet var resultView: NLPResultView!
    let placeholderText = "Enter some text and press Enter"
    //var predictor = NLPPredictor()
    var predictor = NLPMachineTranslation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        textView.text = placeholderText
        textView.textColor = .lightGray
        resultView.config(resultCount: 3)
    }

    @IBAction func onInfoClicked(_: Any) {
        textView.resignFirstResponder()
        NLPModelCard.show()
    }

    @IBAction func onClearClicked(_: Any) {
        textView.text = ""
        resultView.isHidden = true
    }

    @IBAction func onBackClicked(_: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension NLPViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholderText {
            textView.text = ""
            textView.textColor = .white
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = placeholderText
            textView.textColor = .lightGray
            resultView.isHidden = true
        }
    }
    func textView(_ textView: UITextView, shouldChangeTextIn _: NSRange, replacementText text: String) -> Bool {
        if text != "\n" {
            return true
        }
        resultView.isHidden = true
        textView.resignFirstResponder()
        let content = textView.text!
        DispatchQueue.global().async {
            if let results = try? self.predictor.translate(content) {
//            if let results = try? self.predictor.predict(content, resultCount: 3) {
                DispatchQueue.main.async {
                    self.resultView.isHidden = false
                    print(results)
                    //self.resultView.update(results: results)
                }
            }
        }
        return false
    }
}
