// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.


import UIKit

class ViewController: UIViewController {
    var inferencer = QuestionAnswering()
    @IBOutlet weak var tvText: UITextView!
    @IBOutlet weak var tvQuestion: UITextView!
    @IBOutlet weak var tvAnswer: UITextView!
    @IBOutlet weak var btnTest: UIButton!
    @IBOutlet weak var btnAnswer: UIButton!
    
    // text from https://pytorch.org/mobile/home/
    private static let LONG_TEXT = "There is a growing need to execute ML models on edge devices to reduce latency, preserve privacy and enable new interactive use cases. In the past, engineers used to train models separately. They would then go through a multi-step, error prone and often complex process to transform the models for execution on a mobile device. The mobile runtime was often significantly different from the operations available during training leading to inconsistent developer and eventually user experience. PyTorch Mobile removes these friction surfaces by allowing a seamless process to go from training to deployment by staying entirely within the PyTorch ecosystem. It provides an end-to-end workflow that simplifies the research to production environment for mobile devices. In addition, it paves the way for privacy-preserving features via Federated Learning techniques. PyTorch Mobile is in beta stage right now and in wide scale production use. It will soon be available as a stable release once the APIs are locked down. Key features of PyTorch Mobile: Available for iOS, Android and Linux; Provides APIs that cover common preprocessing and integration tasks needed for incorporating ML in mobile applications; Support for tracing and scripting via TorchScript IR; Support for XNNPACK floating point kernel libraries for Arm CPUs; Integration of QNNPACK for 8-bit quantized kernels. Includes support for per-channel quantization, dynamic quantization and more; Build level optimization and selective compilation depending on the operators needed for user applications, i.e., the final binary size of the app is determined by the actual operators the app needs; Support for hardware backends like GPU, DSP, NPU will be available soon."

    private let testTexts = [LONG_TEXT, LONG_TEXT, LONG_TEXT, "Jim Henson was a nice puppet"]
    private let testQuestions = ["What are the key features of pytorch mobile?", "When will support for GPU be available?", "Why on edge devices?", "Who was Henson?"]
    private var testIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tvText.text = testTexts[testIndex]
        tvQuestion.text = testQuestions[testIndex]
    }

    @IBAction func tapTest(_ sender: Any) {
        tvAnswer.text = ""
        if testIndex == testTexts.count - 1 {
            testIndex = -1
            tvText.text = ""
            tvQuestion.text = ""
            btnTest.setTitle("New Test", for:.normal)
            return
        }
        testIndex = (testIndex + 1) % testTexts.count
        tvText.text = testTexts[testIndex]
        tvQuestion.text = testQuestions[testIndex]
        btnTest.setTitle(String(format: "Test %d/%d", testIndex + 1, testTexts.count), for:.normal)
    }
    
    @IBAction func tapAnswer(_ sender: Any) {
        btnAnswer.isEnabled = false
        btnAnswer.setTitle("Running...", for: .normal)

        let question = tvQuestion.text
        let text = tvText.text
        if question == "" || text == "" {
            self.tvAnswer.text = "text and question shouldn't be blank"
            btnAnswer.isEnabled = true
            btnAnswer.setTitle("Answer", for: .normal)
            return
        }
        
        DispatchQueue.global().async {
            let result = self.inferencer.answer(question!, text!)
            DispatchQueue.main.async {
                self.btnAnswer.isEnabled = true
                self.btnAnswer.setTitle("Answer", for: .normal)
                self.tvAnswer.text = result
            
                let attrString = NSMutableAttributedString(string: text!, attributes: [.foregroundColor: UIColor.black, .font: UIFont(name: "HelveticaNeue", size: 17)!])
                let range = text!.lowercased().range(of:result)
                let convertedRange = NSRange(range!, in: text!)
                attrString.addAttributes([.foregroundColor: UIColor.red], range: convertedRange)
                self.tvText.attributedText = attrString                
            }
        }
    }
    
}

