import UIKit
import SDK

class SampleScene : Assembly, Scene {

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
        let viewController = provide(instance: SampleViewController(input: payload), complete: { viewController in
            viewController.completion = segues.completionSegue
        })

        return (viewController,{ payload in
            print("did unwind with \(payload)")
            viewController.title = "\(viewController.input.description) -> \(payload)"
        })
    }
}

class SampleViewController: UIViewController {

    let input: Int
    var completion: ((Int) -> ())!

    init(input: Int) {
        self.input = input
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
