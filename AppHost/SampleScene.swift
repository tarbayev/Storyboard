import UIKit
import SDK

class SampleScene : Assembly, Scene, AssemblyAwakable {

    var completionSegue: Segue<Int>!

    func awakeFromAssembly() {
        assert(completionSegue != nil)
    }

    func instantiateViewController(withPayload payload: Int) -> SampleViewController {
        return provide(instance: SampleViewController(input: payload, completionSegue: completionSegue), complete: { viewController in
            viewController.title = payload.description
        })
    }
}

class SampleViewController: UIViewController {

    let input: Int
    let completionSegue: Segue<Int>

    init(input: Int, completionSegue: Segue<Int>) {
        self.input = input
        self.completionSegue = completionSegue
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBAction func complete() {
        completionSegue.perform(withInput: input + 1, sourceViewController: self)
    }
}
