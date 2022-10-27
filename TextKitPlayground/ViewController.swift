import UIKit

class ViewController: UIViewController {
    @IBOutlet var textView: UITextLabel!
    @IBOutlet var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setAttributedString({
            let string = NSMutableAttributedString(string: "访问 https://www.apple.com/")
            string.setAttributes([
                .link: URL(string: "https://www.apple.com/")!
            ], range: NSRange(location: 3, length: string.length - 3))
            return string
        }())
        self.label.isHidden = true
    }
    
    func setAttributedString(_ string: NSAttributedString) {
        self.textView.attributedText = string
        self.label.attributedText = string
    }
}
