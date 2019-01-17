import UIKit

public protocol StoryboardAwakable {
    func didWireUp()
}

public protocol Scene: StoryboardAwakable {
    associatedtype InputType
    associatedtype UnwindingInputType
    associatedtype InstanceType: UIViewController

    func instantiateViewController(withPayload payload: InputType) -> (viewController: InstanceType, didUnwind: (UnwindingInputType) -> Void)
}

public protocol SegueTransition {
    associatedtype P
    associatedtype S: Scene
    associatedtype B: Storyboard
    func perform(withPayload payload: P,
                 from sourceViewController: UIViewController,
                 toScene identifier: KeyPath<B, S>,
                 inStoryboard storyboard: B)
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

    init<S, P, T>(storyboard: T.B,
                  destiantionIdenditifier: KeyPath<T.B, S>,
                  transition: T,
                  mapPayload: @escaping (PayloadType) -> P)
        where S == T.S, P == T.P, T: SegueTransition {
            perform = { payload, sourceViewController in
                transition.perform(withPayload: mapPayload(payload),
                                   from: sourceViewController,
                                   toScene: destiantionIdenditifier,
                                   inStoryboard: storyboard)
            }
    }

    public func invocation(with viewController: UIViewController) -> (PayloadType) -> Void {
        return { payload in
            self.perform(payload, viewController)
        }
    }
}

typealias SceneIdentifier = AnyKeyPath

class ViewControllerUserInfo {
    let identifier: SceneIdentifier
    private let didUnwind: Any

    init<T>(_ identifier: SceneIdentifier, _ didUnwind: @escaping (T) -> Void) {
        self.identifier = identifier
        self.didUnwind = didUnwind
    }

    func didUnwind<T>(withPayload payload: T) {
        (didUnwind as! (T) -> Void)(payload)
    }
}

fileprivate var ViewControllerUserInfos = NSMapTable<UIViewController, ViewControllerUserInfo>.weakToStrongObjects()

extension UIViewController {

    var sceneIdentifier: SceneIdentifier? {
        return ViewControllerUserInfos.object(forKey: self)?.identifier
    }

    func didUnwind<T>(withPayload payload: T) {
        ViewControllerUserInfos.object(forKey: self)?.didUnwind(withPayload: payload)
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

public struct SceneConnector<B: Storyboard, S: Scene> {

    private let storyboard: B
    private let sourceScene: S

    init(storyboard: B, sourceScene: S) {
        self.storyboard = storyboard
        self.sourceScene = sourceScene
    }

    public func connect<PayloadType, T>
        (_ segueKey: ReferenceWritableKeyPath<S, Segue<PayloadType>?>,
         to sceneIdentifier: KeyPath<T.B, T.S>,
         transition: T,
         mapPayload: @escaping (PayloadType) -> T.P)
        where T: SegueTransition, T.B == B
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

    public func connect<PayloadType, T>
        (_ segueKey: ReferenceWritableKeyPath<S, Segue<PayloadType>?>,
         to sceneIdentifier: KeyPath<T.B, T.S>,
         transition: T)
        where T: SegueTransition, T.B == B, T.P == PayloadType
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

    fileprivate func instantiateViewController<S: Scene>(withPayload payload: S.InputType,
                                                         identifier: KeyPath<Self, S>) -> UIViewController {
        let scene = self[keyPath: identifier]
        let (viewController, didUnwind) = scene.instantiateViewController(withPayload: payload)

        let userInfo = ViewControllerUserInfo(identifier, didUnwind)

        ViewControllerUserInfos.setObject(userInfo, forKey: viewController)

        return viewController
    }
}

public class PushTransition<B: Storyboard, S: Scene>: SegueTransition {

    public init() {}

    public func perform(withPayload payload: S.InputType,
                        from sourceViewController: UIViewController,
                        toScene identifier: KeyPath<B, S>,
                        inStoryboard storyboard: B) {
            let viewController = storyboard.instantiateViewController(withPayload: payload, identifier: identifier)
            sourceViewController.navigationController!.pushViewController(viewController, animated: true)
    }
}

public class PresentingTransition<B: Storyboard, S: Scene>: SegueTransition {

    public init() {}

    public func perform(withPayload payload: S.InputType,
                        from sourceViewController: UIViewController,
                        toScene identifier: KeyPath<B, S>,
                        inStoryboard storyboard: B) {
        let viewController = storyboard.instantiateViewController(withPayload: payload, identifier: identifier)
        sourceViewController.present(viewController, animated: true, completion: nil)
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
    public func allowedChildrenForUnwinding(from sourceViewController: UIViewController) -> [UIViewController] {
        return children.filter { $0 != sourceViewController }
    }

    @objc
    public func unwind(towards viewController: UIViewController) {
    }

    func _unwind(towards viewController: UIViewController) {
        if viewController.presentedViewController == self {
            dismiss(animated: true, completion: nil)
        } else {
            unwind(towards: viewController)
        }
    }

    @discardableResult
    func unwind(toViewControllerWithSceneIdentifier identifier: SceneIdentifier) -> UIViewController? {
        return unwind(from: self, toViewControllerWithSceneIdentifier: identifier)
    }

    func unwind(from sourceViewController: UIViewController,
                toViewControllerWithSceneIdentifier identifier: SceneIdentifier) -> UIViewController? {

        for viewController in allowedChildrenForUnwinding(from: sourceViewController) {
            if let destinationViewController = viewController.unwind(from: self, toViewControllerWithSceneIdentifier: identifier) {
                _unwind(towards: viewController)
                return destinationViewController
            }
        }

        if sceneIdentifier == identifier {
            return self
        }

        if let parent = parent, parent != sourceViewController {
            if let destinationViewController = parent.unwind(from: self, toViewControllerWithSceneIdentifier: identifier) {
                _unwind(towards: parent)
                return destinationViewController
            }
        }

        if let presentingViewController = presentingViewController {
            if let destinationViewController = presentingViewController.unwind(from: self, toViewControllerWithSceneIdentifier: identifier) {
                _unwind(towards: presentingViewController)
                return destinationViewController
            }
        }

        return nil
    }
}

extension UINavigationController {

    override public func allowedChildrenForUnwinding(from sourceViewController: UIViewController) -> [UIViewController] {
        return super.allowedChildrenForUnwinding(from: sourceViewController).reversed()
    }

    override public func unwind(towards viewController: UIViewController) {
        if viewControllers.contains(viewController) {
            popToViewController(viewController, animated: true)
        } else {
            popToRootViewController(animated: true)
        }
    }
}

extension UITabBarController {
    override public func unwind(towards viewController: UIViewController) {
        if viewControllers?.contains(viewController) ?? false {
            selectedViewController = viewController
        }
    }
}

public class UnwindingTransition<B: Storyboard, S: Scene>: SegueTransition {

    public init() {}

    public func perform(withPayload payload: S.UnwindingInputType,
                        from sourceViewController: UIViewController,
                        toScene identifier: KeyPath<B, S>,
                        inStoryboard storyboard: B) {
        sourceViewController.unwind(toViewControllerWithSceneIdentifier: identifier)?.didUnwind(withPayload: payload)
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

    public func instantiateViewController(withPayload payload: Void) -> (viewController: UITabBarController, didUnwind: (()) -> ()) {
        let tabBarController = UITabBarController()

        tabBarController.viewControllers = loadViewControllers()

        return (tabBarController, {_ in })
    }
}

public class NavigationScene: Scene {
    public typealias UnwindingInputType = Void

    let loadRootViewController: () -> UIViewController

    public init(rootScene: Connection) {
        loadRootViewController = {
            rootScene.instantiateViewController()
        }
    }

    public func didWireUp() {}

    public func instantiateViewController(withPayload payload: ()) -> (viewController: UINavigationController, didUnwind: (()) -> ()) {
        return (UINavigationController(rootViewController: loadRootViewController()), {_ in })
    }
}
