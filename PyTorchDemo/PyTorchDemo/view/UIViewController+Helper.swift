import Foundation
import UIKit

extension UIViewController {
    func showAlert(_ error: Swift.Error?) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: error?.localizedDescription ?? "unknown error", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
    }
}
