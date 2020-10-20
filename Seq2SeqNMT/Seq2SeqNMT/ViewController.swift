//
//  ViewController.swift
//  Seq2SeqNMT
//
//  Created by Xiaofei Tang on 9/28/20.
//  Copyright © 2020 Jeff Tang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var tvSource: UITextView!
    @IBOutlet weak var tvTarget: UITextView!
    var predictor = NLPMachineTranslation()
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Do any additional setup after loading the view.
    }

    @IBAction func tapTranslate(_ sender: Any) {
        let source = self.tvSource.text!
        DispatchQueue.global().async {
            let results = self.predictor.translate(source)
            DispatchQueue.main.async {
                self.tvTarget.text = results
            }
        }
    }
    
}

