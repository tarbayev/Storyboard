import UIKit

public protocol StoryboardAwakable {
    func didWireUp()
}

public protocol Scene: StoryboardAwakable {
    associatedtype InputType
    associatedtype InstanceType: UIViewController

    func instantiateViewController(withPayload payload: InputType) -> InstanceType
}

public protocol SegueTransition {
    func perform(sourceViewController: UIViewController,
                 destinationViewController: @autoclosure () -> UIViewController,
                 identifier: AnyKeyPath)
}

public class Connection {

    init<B: Storyboard, S: Scene>(storyboard: B,
               destiantionIdenditifier: KeyPath<B, S>,
               payload: S.InputType)
    {
            instantiateViewController = {
                storyboard.instantiateViewController(withPayload: payload, identifier: destiantionIdenditifier)
            }
    }

    public let instantiateViewController: () -> UIViewController
}

public class Segue<PayloadType> {

    private let perform: (PayloadType, UIViewController) -> Void

    init<B, S, P>(storyboard: B,
                  destiantionIdenditifier: KeyPath<B, S>,
                  transition: SegueTransition,
                  mapPayload: @escaping (PayloadType) -> P)
        where B: Storyboard, S: Scene, P == S.InputType {
            perform = { payload, sourceViewController in
                transition.perform(sourceViewController: sourceViewController,
                                   destinationViewController: storyboard.instantiateViewController(withPayload: mapPayload(payload), identifier: destiantionIdenditifier),
                                   identifier: destiantionIdenditifier)
            }
    }

    public func invocation(with viewController: UIViewController) -> (PayloadType) -> Void {
        return { payload in
            self.perform(payload, viewController)
        }
    }
}

typealias SceneIdentifier = AnyKeyPath

fileprivate var ViewControllerIdentifiers = NSMapTable<UIViewController, SceneIdentifier>.weakToStrongObjects()

extension UIViewController {

    var sceneIdentifier: SceneIdentifier? {
        return ViewControllerIdentifiers.object(forKey: self)
    }
}

public protocol Storyboard: class {

    associatedtype RootSceneType: Scene where RootSceneType.InputType == Void
    static var rootIdentifier: KeyPath<Self, RootSceneType> { get }
}

class SetClass<T: Hashable> {
    var set: Set<T> = []
}

fileprivate var StoryboardSceneKeys = NSMapTable<AnyObject, SetClass<AnyKeyPath>>.weakToStrongObjects()

public struct SceneConnector<S: Storyboard, SS: Scene> {

    private let storyboard: S
    private let sourceScene: SS

    init(storyboard: S, sourceScene: SS) {
        self.storyboard = storyboard
        self.sourceScene = sourceScene
    }

    public func connect<PayloadType, FinalPayloadType, DS: Scene>
        (_ segueKey: ReferenceWritableKeyPath<SS, Segue<PayloadType>?>,
         to sceneIdentifier: KeyPath<S, DS>,
         transition: SegueTransition,
         mapPayload: @escaping (PayloadType) -> FinalPayloadType)
        where DS.InputType == FinalPayloadType, DS.InstanceType == UIViewController
    {
        sourceScene[keyPath: segueKey] = Segue(storyboard: storyboard,
                                               destiantionIdenditifier: sceneIdentifier,
                                               transition: transition,
                                               mapPayload: mapPayload)

        let keys = StoryboardSceneKeys.object(forKey: storyboard) ?? {
            let keySet = SetClass<AnyKeyPath>()
            StoryboardSceneKeys.setObject(keySet, forKey: storyboard)
            return keySet
        } ()

        keys.set.insert(sceneIdentifier)
    }

    public func connect<PayloadType, DS: Scene>
        (_ segueKey: ReferenceWritableKeyPath<SS, Segue<PayloadType>?>,
         to sceneIdentifier: KeyPath<S, DS>,
         transition: SegueTransition)
        where DS.InputType == PayloadType, DS.InstanceType == UIViewController
    {
        connect(segueKey, to: sceneIdentifier, transition: transition, mapPayload: { $0 })
    }
}

public extension Storyboard {

    public func connection<S: Scene>
        (to sceneIdentifier: KeyPath<Self, S>,
         payload: S.InputType) -> Connection {
        return Connection(storyboard: self, destiantionIdenditifier: sceneIdentifier, payload: payload)
    }

    public func connection<S: Scene>(to sceneIdentifier: KeyPath<Self, S>) -> Connection
        where S.InputType == Void {
            return connection(to: sceneIdentifier, payload: ())
    }

    public func connect<SS: Scene>
        (_ sourceScene: SS,
         _ connection: (SceneConnector<Self, SS>) -> Void)
    {
        let connector = SceneConnector(storyboard: self, sourceScene: sourceScene)
        connection(connector)
    }

    public func instantiateRootViewController() -> UIViewController {
        if let keys = StoryboardSceneKeys.object(forKey: self)?.set {
            keys.forEach { key in
                let scene = self[keyPath: key] as! StoryboardAwakable
                scene.didWireUp()
            }
            StoryboardSceneKeys.removeObject(forKey: self)
        }
        return instantiateViewController(withPayload: (), identifier: Self.rootIdentifier)
    }

    fileprivate func instantiateViewController<InputType, S: Scene>(withPayload payload: InputType,
                                                        identifier: KeyPath<Self, S>) -> UIViewController
        where S.InputType == InputType {
            let scene = self[keyPath: identifier]
            let viewController = scene.instantiateViewController(withPayload: payload)

            ViewControllerIdentifiers.setObject(identifier, forKey: viewController)

            return viewController
    }
}

public class PushTransition: SegueTransition {

    public init() {}

    public func perform(sourceViewController: UIViewController, destinationViewController: @autoclosure () -> UIViewController, identifier: AnyKeyPath) {
        sourceViewController.navigationController!.pushViewController(destinationViewController(), animated: true)
    }
}

public class PresentingTransition: SegueTransition {

    public init() {}

    public func perform(sourceViewController: UIViewController, destinationViewController: @autoclosure () -> UIViewController, identifier: AnyKeyPath) {
        sourceViewController.present(destinationViewController(), animated: true, completion: nil)
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

    @objc
    func allowedChildrenForUnwinding(from sourceViewController: UIViewController) -> [UIViewController] {
        return children.filter { $0 != sourceViewController }
    }

    @discardableResult
    func unwind(toViewControllerWithSceneIdentifier identifier: SceneIdentifier) -> Bool {
        return unwind(from: self, toViewControllerWithSceneIdentifier: identifier)
    }

    @objc
    func unwind(towards: UIViewController) {
        if towards.presentedViewController == self {
            dismiss(animated: true, completion: nil)
        }
    }

    @discardableResult
    func unwind(from sourceViewController: UIViewController, toViewControllerWithSceneIdentifier identifier: SceneIdentifier) -> Bool {

        if let viewController = allowedChildrenForUnwinding(from: sourceViewController)
            .first(where: { $0.unwind(from: self, toViewControllerWithSceneIdentifier: identifier) }) {
            unwind(towards: viewController)
            return true
        }

        if sceneIdentifier == identifier {
            return true
        }

        if let parent = parent, parent != sourceViewController {
            if parent.unwind(from: self, toViewControllerWithSceneIdentifier: identifier) {
                unwind(towards: parent)
                return true
            }
        }

        if let presentingViewController = presentingViewController {
            if presentingViewController.unwind(from: self, toViewControllerWithSceneIdentifier: identifier) {
                unwind(towards: presentingViewController)
                return true
            }
        }

        return false
    }
}

extension UINavigationController {

    override func allowedChildrenForUnwinding(from sourceViewController: UIViewController) -> [UIViewController] {
        return super.allowedChildrenForUnwinding(from: sourceViewController).reversed()
    }

    override func unwind(towards: UIViewController) {
        if viewControllers.contains(towards) {
            popToViewController(towards, animated: true)
        } else {
            popToRootViewController(animated: true)
        }

        super.unwind(towards: towards)
    }
}

extension UITabBarController {
    override func unwind(towards: UIViewController) {
        if viewControllers?.contains(towards) ?? false {
            selectedViewController = towards
        }

        super.unwind(towards: towards)
    }
}

public class UnwindingTransition: SegueTransition {

    public init() {}

    public func perform(sourceViewController: UIViewController, destinationViewController: @autoclosure () -> UIViewController, identifier: AnyKeyPath) {
        sourceViewController.unwind(toViewControllerWithSceneIdentifier: identifier)
    }
}

public class TabBarScene: Scene {

    let loadViewControllers: () -> [UIViewController]

    public init(scenes: [Connection]) {
        loadViewControllers = {
            scenes.map { $0.instantiateViewController() }
        }
    }

    public func didWireUp() {}

    public func instantiateViewController(withPayload payload: ()) -> UITabBarController {
        let tabBarController = UITabBarController()

        tabBarController.viewControllers = loadViewControllers()

        return tabBarController
    }
}

public class NavigationScene: Scene {

    let loadRootViewController: () -> UIViewController

    public init(rootScene: Connection) {
        loadRootViewController = {
            rootScene.instantiateViewController()
        }
    }

    public func didWireUp() {}

    public func instantiateViewController(withPayload payload: ()) -> UINavigationController {
        return UINavigationController(rootViewController: loadRootViewController())
    }
}
