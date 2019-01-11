import UIKit
import SDK

class SampleScene : Assembly, Scene {

    var completionSegue: Segue<Int>!

    public func didWireUp() {
        assert(completionSegue != nil)
    }

    func instantiateViewController(withPayload payload: Int) -> UIViewController {
        return provide(instance: SampleViewController(input: payload), complete: { viewController in
            viewController.title = payload.description
            viewController.completion = self.completionSegue.invocation(with: viewController)
        })
    }
}

class SampleViewController: UIViewController {

    let input: Int
    var completion: ((Int) -> ())!

    init(input: Int) {
        self.input = input
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBAction func complete() {
        completion(input + 1)
    }
}
