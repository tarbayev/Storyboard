import UIKit
import SDK

class DetailScene : Assembly, Scene {

    func instantiateViewController(withPayload payload: String) -> UIViewController {
        self.payload = payload
        return viewController
    }
}

private extension DetailScene {

    var payload: String {
        set {
            register(external: newValue)
        }
        get {
            return external()
        }
    }

    var viewController: UIViewController {
        let loadViewController: () -> UIViewController = {
            let viewController = UIViewController()
            viewController.title = self.payload
            viewController.view.backgroundColor = UIColor.white
            return viewController
        }
        return provide(instance: loadViewController())
    }
}
