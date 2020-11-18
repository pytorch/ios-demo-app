import UIKit

extension UIImage {
    func resized(to newSize: CGSize, scale: CGFloat = 1) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let image = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
        return image
    }
    
    func normalized() -> [Float32]? {
        guard let cgImage = self.cgImage else {
            return nil
        }
        let w = cgImage.width
        let h = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * w
        let bitsPerComponent = 8
        var rawBytes: [UInt8] = [UInt8](repeating: 0, count: w * h * 4)
        rawBytes.withUnsafeMutableBytes { ptr in
            if let cgImage = self.cgImage,
                let context = CGContext(data: ptr.baseAddress,
                                        width: w,
                                        height: h,
                                        bitsPerComponent: bitsPerComponent,
                                        bytesPerRow: bytesPerRow,
                                        space: CGColorSpaceCreateDeviceRGB(),
                                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
                let rect = CGRect(x: 0, y: 0, width: w, height: h)
                context.draw(cgImage, in: rect)
            }
        }
        var normalizedBuffer: [Float32] = [Float32](repeating: 0, count: w * h * 3)
        for i in 0 ..< w * h {
            normalizedBuffer[i] = Float32(rawBytes[i * 4 + 0]) / 255.0
            normalizedBuffer[w * h + i] = Float32(rawBytes[i * 4 + 1]) / 255.0
            normalizedBuffer[w * h * 2 + i] = Float32(rawBytes[i * 4 + 2]) / 255.0 
        }
        return normalizedBuffer
    }
}



///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// code below about NMS is from  https://github.com/hollance/YOLO-CoreML-MPSNNGraph/blob/master/Common/Helpers.swift
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
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



// outputs is of size 25200*85, each row starts with left,top,right,bottom,score and 80 class probability (? - sum of 80 values not exactly same as 1.0: sum(prediction[0, 24599][5:]) is 0.7299)
func outputsToNMSPredictions(outputs: Array<NSNumber>, imgScaleX: Double, imgScaleY: Double, ivScaleX: Double, ivScaleY: Double, startX: Double, startY: Double) -> [Prediction] {
    var predictions = [Prediction]()
    for i in 0..<25200 {
        if Double(outputs[i*85+4]) > 0.35 {
            let x = Double(outputs[i*85])
            let y = Double(outputs[i*85+1])
            let w = Double(outputs[i*85+2])
            let h = Double(outputs[i*85+3])
            
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

            let rect = CGRect(x: startX+ivScaleX*left, y: startY+top*ivScaleY, width: ivScaleX*(right-left), height: ivScaleY*(bottom-top))
            
            let prediction = Prediction(classIndex: cls, score: Float(outputs[i*85+4]), rect: rect)
            predictions.append(prediction)
        }
    }

    return nonMaxSuppression(boxes: predictions, limit: 15, threshold: 0.3)
}



func cleanDrawing(imageView: UIImageView) {
    if let layers = imageView.layer.sublayers {
        for layer in layers {
            if layer is CATextLayer {
                layer.removeFromSuperlayer()
            }
        }
        for view in imageView.subviews {
            view.removeFromSuperview()
        }
    }
}
