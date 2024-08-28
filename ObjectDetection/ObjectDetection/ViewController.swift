// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var btnRun: UIButton!
    @IBOutlet weak var btnNext: UIButton!

    private let testImages = ["test1.png", "test2.jpg", "test3.png"]
    private var imgIndex = 0

    private var image : UIImage?
    private var inferencer = ObjectDetector()

    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: testImages[imgIndex])!
        if let iv = imageView {
            iv.image = image
            btnRun.setTitle("Detect", for: .normal)
        }
    }

    @IBAction func runTapped(_ sender: Any) {
        btnRun.isEnabled = false
        btnRun.setTitle("Running the model...", for: .normal)

        let resizedImage = image!.resized(to: CGSize(width: CGFloat(PrePostProcessor.inputWidth), height: CGFloat(PrePostProcessor.inputHeight)))

        let imgScaleX = Double(image!.size.width / CGFloat(PrePostProcessor.inputWidth));
        let imgScaleY = Double(image!.size.height / CGFloat(PrePostProcessor.inputHeight));

        let ivScaleX : Double = (image!.size.width > image!.size.height ? Double(imageView.frame.size.width / image!.size.width) : Double(imageView.frame.size.height / image!.size.height))
        let ivScaleY : Double = (image!.size.height > image!.size.width ? Double(imageView.frame.size.height / image!.size.height) : Double(imageView.frame.size.width / image!.size.width))

        let startX = Double((imageView.frame.size.width - CGFloat(ivScaleX) * image!.size.width)/2)
        let startY = Double((imageView.frame.size.height -  CGFloat(ivScaleY) * image!.size.height)/2)

        guard let pixelBuffer = resizedImage.normalized() else {
            return
        }

        DispatchQueue.global().async {
            // UnsafeMutablePointer() doesn't guarantee that the converted pointer points to the memory that is still being allocated
            // So we create a new pointer and copy the &pixelBuffer's memory to where it points to
            let copiedBufferPtr = UnsafeMutablePointer<Float>.allocate(capacity: pixelBuffer.count)
            copiedBufferPtr.initialize(from: pixelBuffer, count: pixelBuffer.count)
            guard let outputs = self.inferencer.module.detect(image: copiedBufferPtr) else {
                copiedBufferPtr.deallocate()
                return
            }
            copiedBufferPtr.deallocate()

            let nmsPredictions = PrePostProcessor.outputsToNMSPredictions(outputs: outputs, imgScaleX: imgScaleX, imgScaleY: imgScaleY, ivScaleX: ivScaleX, ivScaleY: ivScaleY, startX: startX, startY: startY)

            DispatchQueue.main.async {
                PrePostProcessor.showDetection(imageView: self.imageView, nmsPredictions: nmsPredictions, classes: self.inferencer.classes)
                self.btnRun.isEnabled = true
                self.btnRun.setTitle("Detect", for: .normal)
            }
        }
    }

    @IBAction func nextTapped(_ sender: Any) {
        PrePostProcessor.cleanDetection(imageView: imageView)
        imgIndex = (imgIndex + 1) % testImages.count
        btnNext.setTitle(String(format: "Text Image %d/%d", imgIndex + 1, testImages.count), for:.normal)
        image = UIImage(named: testImages[imgIndex])!
        imageView.image = image
    }

    @IBAction func photosTapped(_ sender: Any) {
        PrePostProcessor.cleanDetection(imageView: imageView)
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self;
        imagePickerController.sourceType = .photoLibrary
        self.present(imagePickerController, animated: true, completion: nil)
    }

    @IBAction func cameraTapped(_ sender: Any) {
        PrePostProcessor.cleanDetection(imageView: imageView)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self;
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true, completion: nil)
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        image = image!.resized(to: CGSize(width: CGFloat(PrePostProcessor.inputWidth), height: CGFloat(PrePostProcessor.inputHeight)*image!.size.height/image!.size.width))
        imageView.image = image
        self.dismiss(animated: true, completion: nil)
    }
}
