import UIKit

struct Prediction {
  let confidence: Float
  let label: String
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var predictButton: UIButton!
  @IBOutlet weak var imageStepper: UIStepper!
  @IBOutlet weak var durationLabel: UILabel!
  @IBOutlet weak var resultsView: UITableView!

  var predictions = [Prediction]()

  let width: Int = 224
  let height: Int = 224

  private lazy var module: TorchModule = {
    guard let filePath = Bundle.main.path(forResource: "model", ofType: "pt"),
          let module = TorchModule(fileAtPath: filePath, width: width, height: height)
    else {
      fatalError("Can't find the model file!")
    }
    return module
  }()

  private lazy var labels: [Substring] = {
    guard let filePath = Bundle.main.path(forResource: "words", ofType: "txt"),
          let labels = try? String(contentsOfFile: filePath)
    else {
      fatalError("Can't find the text file!")
    }
    return labels.split(whereSeparator: \.isNewline)
  }()

  private lazy var images: [UIImage?] = {
    let imagePaths = Bundle.main.paths(forResourcesOfType: "jpg", inDirectory: nil) +
    Bundle.main.paths(forResourcesOfType: "png", inDirectory: nil)
    print(imagePaths)
    return imagePaths.map { UIImage(named: $0) }
  }()

  private var activeImage: UIImage? { images[Int(imageStepper.value)] }

  override func viewDidLoad() {
    super.viewDidLoad()
    resultsView.dataSource = self
    imageStepper.value = 0
    imageStepper.minimumValue = 0
    imageStepper.maximumValue = Double(images.count - 1)
    updateImageView()
    doPrediction()
  }

  func updateImageView() {
    imageView.image = images[Int(imageStepper.value)]
  }

  private var imageFloats: [Float32]? {
    guard let resizedImage = activeImage?.resized(to: CGSize(width: width, height: height)) else { return nil }
    return resizedImage.normalized()
  }

  func doPrediction() {
    guard var input = self.imageFloats else { return }
    predictions.removeAll()
    resultsView.reloadData()

    input.withUnsafeMutableBufferPointer { ptr in
      let startTime: DispatchTime = .now()
      if let output = module.predict(image: &(ptr.baseAddress!.pointee)) {
        let duration = TimeInterval(dispatchTimeInterval: startTime.distance(to: .now()))!
        durationLabel.text = String(format: "%.3f seconds", duration)

        let bufferPointer = UnsafeBufferPointer(start: output, count: labels.count)
        let indexedResults = bufferPointer.enumerated()
        let top3 = indexedResults.sorted { $0.1 > $1.1 }.prefix(4)

        for result in top3 {
          predictions.append(Prediction(confidence: result.1, label: String(labels[result.0])))
        }
        resultsView.reloadData()
      }
    }
  }

  @IBAction func changeImage(_ sender: Any) {
    updateImageView()
    doPrediction()
  }

  @IBAction func runPredict(_ sender: Any) {
    doPrediction()
  }
}

extension ViewController {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    predictions.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "result", for: indexPath)
    cell.textLabel?.text = predictions[indexPath.row].label
    cell.detailTextLabel?.text = String(format: "%.2f", predictions[indexPath.row].confidence)
    return cell
  }
}

extension TimeInterval {

  init?(dispatchTimeInterval: DispatchTimeInterval) {
    switch dispatchTimeInterval {
    case .seconds(let value): self = Double(value)
    case .milliseconds(let value): self = Double(value) / 1_000
    case .microseconds(let value): self = Double(value) / 1_000_000
    case .nanoseconds(let value):  self = Double(value) / 1_000_000_000
    case .never: return nil
    @unknown default: return nil
    }
  }
}
