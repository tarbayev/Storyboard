import UIKit
import SDK

class HomeScene : Assembly, Scene, AssemblyAwakable {

    var showDetails: Segue<String>!

    func awakeFromAssembly() {
        assert(showDetails != nil)
    }

    func instantiateViewController(withPayload payload: Void) -> UIViewController {
        return viewController
    }
}

private extension HomeScene {

    var viewController: UIViewController {
        let loadViewController: () -> UIViewController = {
            let viewController = Bundle.main.loadNibNamed("HomeViewController", owner: nil, options: [
                UINib.OptionsKey.externalObjects : ["DetailHandler" : self.detailHandler]
                ])![0] as! UIViewController

            viewController.title = "Home"

            return viewController
        }
        return provide(instance: loadViewController())
    }

    var detailHandler: DetailActionHandler {
        return provide(instance: DetailActionHandler(detailSegue: showDetails), complete: { handler in
            handler.sourceViewController = self.viewController
        })
    }

    class DetailActionHandler: NSObject, AssemblyAwakable {

        private let detailSegue: Segue<String>
        init(detailSegue: Segue<String>) {
            self.detailSegue = detailSegue
        }

        var sourceViewController: UIViewController!

        func awakeFromAssembly() {
            assert(sourceViewController != nil)
        }

        @IBAction func detailButtonTapped(sender: UIButton) {
            detailSegue.perform(withInput: "Lorem ipsum dolor sit amet", sourceViewController: sourceViewController)
        }
    }
}
