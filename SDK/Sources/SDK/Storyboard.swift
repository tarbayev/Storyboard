import UIKit
import ObjectiveC

public protocol Scene {
    associatedtype InputType
    associatedtype InstanceType: UIViewController

    func instantiateViewController(withPayload payload: InputType) -> InstanceType
}

public protocol SegueTransition {
    func perform(sourceViewController: UIViewController,
                 destinationViewController: @autoclosure () -> UIViewController,
                 identifier: AnyKeyPath)
}

public class Segue<PayloadType> {

    let perform: (PayloadType, UIViewController) -> Void

    init<B: Storyboard, S: Scene>(storyboard: B,
               destiantionIdenditifier: KeyPath<B, S>,
               transition: SegueTransition)
        where S.InputType == PayloadType {
            perform = { payload, sourceViewController in
                transition.perform(sourceViewController: sourceViewController,
                                   destinationViewController: storyboard.instantiateViewController(withPayload: payload, identifier: destiantionIdenditifier),
                                   identifier: destiantionIdenditifier)
            }
    }

    public func perform(withInput input: PayloadType, sourceViewController: UIViewController) {
        perform(input, sourceViewController)
    }
}

fileprivate var ViewControllerIdentifiers: [UIViewController:AnyKeyPath] = [:]

extension UIViewController {

    var identifier: AnyKeyPath? {
        return ViewControllerIdentifiers[self]
    }
}

public protocol Storyboard {
//    var rootIdentifier: AnyKeyPath { get }
}

public extension Storyboard {

    public func segue<PayloadType, S: Scene>(to sceneIdentifier: KeyPath<Self, S>, transition: SegueTransition) -> Segue<PayloadType>
         where S.InputType == PayloadType, S.InstanceType == UIViewController
    {
        return Segue(storyboard: self, destiantionIdenditifier: sceneIdentifier, transition: transition)
    }

//    public func instantiateRootViewController() -> UIViewController {
//        return instantiateViewController(withPayload: (), identifier: rootIdentifier)
//    }

    func instantiateViewController<InputType, S: Scene>(withPayload payload: InputType,
                                                        identifier: KeyPath<Self, S>) -> UIViewController
        where S.InputType == InputType {
            let scene = self[keyPath: identifier]
            let viewController = scene.instantiateViewController(withPayload: payload)

            ViewControllerIdentifiers[viewController] = identifier

            return viewController
    }
}

public class PushSegue: SegueTransition {

    public init() {}

    public func perform(sourceViewController: UIViewController, destinationViewController: @autoclosure () -> UIViewController, identifier: AnyKeyPath) {
        sourceViewController.navigationController!.pushViewController(destinationViewController(), animated: true)
    }
}

//public class ReplacingSegue<Destination: Scene>: Segue<Destination.InputType> {
//    private let destination: Destination
//
//    public init(destination: Destination) {
//        self.destination = destination
//    }
//
//    public override func perform(withInput input: Destination.InputType, sourceViewController: UIViewController) {
//        let identifier = destination.identifier
//
//        let navigationController = sourceViewController.navigationController!
//
//        var viewControllers = Array(navigationController.viewControllers.prefix(while: { $0.identifier != identifier }))
//
//        viewControllers.append(destination.instantiateViewController(withPayload: input))
//
//        navigationController.setViewControllers(viewControllers, animated: true)
//    }
//}
//
extension UIViewController {
    @discardableResult
    func revealViewController(withIdentifier identifier: AnyKeyPath) -> Bool {
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

public class ActivationgSegue: SegueTransition {

    public init() {}

    public func perform(sourceViewController: UIViewController, destinationViewController: @autoclosure () -> UIViewController, identifier: AnyKeyPath) {
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
