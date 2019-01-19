import UIKit
import SDK

class SampleScene : Scene {

    class Segues: SeguesContainer {
        var completionSegue: Segue<Int>!
    }

    var sampleInput: Int {
        return Int.random(in: 0...100)
    }
    var sampleUnwindingInput: String {
        return "Sample string"
    }

    func instantiate(withPayload payload: Int, segues: Segues) -> (UIViewController, didUnwind: (String) -> Void) {
        let viewController = SampleViewController(input: payload, completion: segues.completionSegue)
        let didUnwind = { (payload: String) in
            print("did unwind with \(payload)")
            viewController.title = "\(viewController.input.description) <- \(payload)"
        }
        return (viewController, didUnwind)
    }
}

class SampleViewController: UIViewController {

    let input: Int
    let completion: (Int) -> Void

    init(input: Int, completion: @escaping (Int) -> Void) {
        self.input = input
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        self.title = input.description
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBAction func complete() {
        completion(input + 1)
    }
}
