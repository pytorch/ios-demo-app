// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var tvSource: UITextView!
    @IBOutlet weak var tvTarget: UITextView!
    var inferencer = MachineTranslation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func tapTranslate(_ sender: Any) {
        let source = self.tvSource.text!
        DispatchQueue.global().async {
            let results = self.inferencer.translate(source)
            DispatchQueue.main.async {
                self.tvTarget.text = results
            }
        }
    }
}

