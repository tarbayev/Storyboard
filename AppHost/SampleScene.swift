import UIKit
import SDK

class SampleScene : Assembly, Scene {

    var completionSegue: Segue<Int>!

    public func didWireUp() {
        assert(completionSegue != nil)
    }

    func instantiateViewController(withPayload payload: Int) -> (viewController: UIViewController, didUnwind: (Int) -> Void) {
        let viewController = provide(instance: SampleViewController(input: payload), complete: { viewController in
            viewController.completion = self.completionSegue.invocation(with: viewController)
        })

        return (viewController,{ payload in
            print("did unwind with \(payload)")
            viewController.input = payload
        })
    }
}

class SampleViewController: UIViewController {

    var input: Int = 0 {
        didSet {
            title = input.description
        }
    }
    var completion: ((Int) -> ())!

    init(input: Int) {
        defer {
            self.input = input
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBAction func complete() {
        completion(input + 1)
    }
}
