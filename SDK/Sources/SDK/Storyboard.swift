import UIKit

public struct Storyboard {
    
}

public protocol Scene {
    associatedtype InputType
    associatedtype InstanceType: UIViewController

    var identifier: String { get }

    func instantiateViewController(withPayload payload: InputType) -> InstanceType
}

public class Segue<InputType> {
    public func perform(withInput input: InputType, sourceViewController: UIViewController) {}
}

public class PushSegue<Destination: Scene>: Segue<Destination.InputType> {
    private let destination: Destination

    public init(destination: Destination) {
        self.destination = destination
    }

    public override func perform(withInput input: Destination.InputType, sourceViewController: UIViewController) {
        let viewController = destination.instantiateViewController(withPayload: input)
        sourceViewController.navigationController!.pushViewController(viewController, animated: true)
    }
}

extension UIViewController {
    var identifier: UIViewController.Type {
        return type(of: self)
    }
}

public class ReplacingSegue<Destination: Scene>: Segue<Destination.InputType> {
    private let destination: Destination

    public init(destination: Destination) {
        self.destination = destination
    }

    public override func perform(withInput input: Destination.InputType, sourceViewController: UIViewController) {
        let identifier = destination.identifier

        let navigationController = sourceViewController.navigationController!

        var viewControllers = Array(navigationController.viewControllers.prefix(while: { $0.identifier != identifier }))

        viewControllers.append(destination.instantiateViewController(withPayload: input))

        navigationController.setViewControllers(viewControllers, animated: true)
    }
}

extension UIViewController {
    @discardableResult
    func revealViewController<T>(withIdentifier identifier: T.Type) -> Bool {
        print(identifier)
        switch self {
        case let navigationController as UINavigationController:
            if let viewController = navigationController.viewControllers.first(where: { $0.identifier == identifier }) {
                navigationController.popToViewController(viewController, animated: true)
                return true
            }

        case let tabBarController as UITabBarController:
            for viewController in tabBarController.viewControllers! {
                if viewController.revealViewController(withIdentifier: identifier) {
                    return true
                }
            }

        default:

            if var viewController = self.parent {
                while let parent = viewController.parent {
                    viewController = parent
                }

                return viewController.revealViewController(withIdentifier: identifier)
            }
        }

        return false
    }
}

public class ActivationgSegue<Destination: Scene>: Segue<Destination.InputType> {
    private let destination: Destination

    public init(destination: Destination) {
        self.destination = destination
    }

    public override func perform(withInput input: Destination.InputType, sourceViewController: UIViewController) {
        let identifier = destination.identifier

        sourceViewController.revealViewController(withIdentifier: identifier)
    }
}

public struct StaticScene: Scene {
    let instantiateViewController: () -> UIViewController

    public init<S: Scene>(scene: S, input: S.InputType) {
        instantiateViewController = {
            scene.instantiateViewController(withPayload: input)
        }
    }

    public func instantiateViewController(withPayload payload: Void) -> UIViewController {
        return instantiateViewController()
    }
}

// extension Scene {
//    func staticScene<S: Scene>(withInput: InputType) -> S where S.InputType == Void {
//        return StaticScene(scene: self, input: withInput)
//    }
// }

public class TabBarScene: Scene {
    let loadViewControllers: () -> [UIViewController]

    public init<S: Scene>(scenes: [S]) where S.InputType == Void {
        loadViewControllers = {
            scenes.map { $0.instantiateViewController(withPayload: ()) }
        }
    }

    public func instantiateViewController(withPayload payload: ()) -> UITabBarController {
        let tabBarController = UITabBarController()

        tabBarController.viewControllers = loadViewControllers()

        return tabBarController
    }
}

public class NavigationScene: Scene {
    let loadRootViewController: () -> UIViewController

    public init<S: Scene>(rootScene: S) where S.InputType == Void {
        loadRootViewController = {
            rootScene.instantiateViewController(withPayload: ())
        }
    }

    public func instantiateViewController(withPayload payload: ()) -> UINavigationController {
        return UINavigationController(rootViewController: loadRootViewController())
    }
}
