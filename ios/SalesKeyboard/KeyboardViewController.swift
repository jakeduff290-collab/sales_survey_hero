import UIKit

class KeyboardViewController: UIInputViewController {
    let defaults = UserDefaults(suiteName: "group.com.example.salesSurveyHero")

    func insertNameTapped() {
        if let clientName = defaults?.string(forKey: "clientName") {
            self.textDocumentProxy.insertText(clientName)
        }
    }
}
