import UIKit

public typealias UnwindingHandler<T> = (T) -> Void
public typealias SceneInstance<VC: UIViewController, U> = (VC, didUnwind: UnwindingHandler<U>)

open class SeguesContainer {
    var viewController: UIViewController!
    required public init() {}
}

public protocol Scene: class {
    associatedtype InputType
    associatedtype UnwindingInputType
    associatedtype SeguesContainerType: SeguesContainer
    associatedtype InstanceType: UIViewController

    #if DEBUG
    var sampleInput: InputType { get }
    var sampleUnwindingInput: UnwindingInputType { get }
    #endif

    func instantiate(withPayload payload: InputType, segues: SeguesContainerType) -> SceneInstance<InstanceType, UnwindingInputType>
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

public typealias Segue<PayloadType> = (PayloadType) -> Void

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

fileprivate var viewControllerUserInfos = NSMapTable<UIViewController, ViewControllerUserInfo>.weakToStrongObjects()

extension UIViewController {

    var sceneIdentifier: SceneIdentifier? {
        return viewControllerUserInfos.object(forKey: self)?.identifier
    }

    func didUnwind<T>(withPayload payload: T) {
        viewControllerUserInfos.object(forKey: self)?.didUnwind(withPayload: payload)
    }
}

public protocol Storyboard: class {

    associatedtype RootSceneType: Scene where RootSceneType.InputType == Void
    static var rootIdentifier: KeyPath<Self, RootSceneType> { get }
}

class ClassContainer<T> {
    var value: T
    init(_ value: T) {
        self.value = value
    }
}

#if DEBUG
let storyboardValidatedIdentifiers = NSMapTable<AnyObject, ClassContainer<Set<AnyKeyPath>>>.weakToStrongObjects()
#endif

public struct SceneConnector<B: Storyboard, C: SeguesContainer> {

    private let storyboard: B
    private let container: C

    init(storyboard: B, container: C) {
        self.storyboard = storyboard
        self.container = container
    }

    public func connect<PayloadType, T>
        (_ segueKey: ReferenceWritableKeyPath<C, Segue<PayloadType>?>,
         to sceneIdentifier: KeyPath<T.B, T.S>,
         transition: T,
         mapPayload: @escaping (PayloadType) -> T.P)
        where T: SegueTransition, T.B == B
    {
        let c = container
        let s = storyboard

        container[keyPath: segueKey] = { payload in
            transition.perform(withPayload: mapPayload(payload),
                               from: c.viewController,
                               toScene: sceneIdentifier,
                               inStoryboard: s)
        }

        #if DEBUG
        let keys = storyboardValidatedIdentifiers.object(forKey: s) ?? {
            let keySet = ClassContainer(Set<AnyKeyPath>())
            storyboardValidatedIdentifiers.setObject(keySet, forKey: s)
            return keySet
            } ()

        if keys.value.insert(sceneIdentifier).inserted {
            let scene = s[keyPath: sceneIdentifier]
            let viewController = s.instantiateViewController(withPayload: scene.sampleInput, identifier: sceneIdentifier)
            viewController.didUnwind(withPayload: scene.sampleUnwindingInput)
        }
        #endif
    }

    public func connect<PayloadType, T>
        (_ segueKey: ReferenceWritableKeyPath<C, Segue<PayloadType>?>,
         to sceneIdentifier: KeyPath<T.B, T.S>,
         transition: T)
        where T: SegueTransition, T.B == B, T.P == PayloadType
    {
        connect(segueKey, to: sceneIdentifier, transition: transition, mapPayload: { $0 })
    }
}

let storyboardSceneConnectors = NSMapTable<AnyObject, ClassContainer<Any>>.weakToStrongObjects()

extension Scene {
    func setSeguesConnector<B:Storyboard>(_ connector: @escaping (SceneConnector<B, SeguesContainerType>) -> Void) {
        storyboardSceneConnectors.setObject(ClassContainer(connector), forKey: self)
    }
    func segues<B:Storyboard>(inStoryboard: B) -> SeguesContainerType {
        let segues = SeguesContainerType()
        if let connect = storyboardSceneConnectors.object(forKey: self)?.value as? (SceneConnector<B, SeguesContainerType>) -> Void {
            let connector = SceneConnector(storyboard: inStoryboard, container: segues)
            connect(connector)
        }
        return segues
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
         _ connection: @escaping (SceneConnector<Self, SS.SeguesContainerType>) -> Void)
    {
        sourceScene.setSeguesConnector(connection)
    }

    public func instantiateRootViewController() -> UIViewController {
        return instantiateViewController(withPayload: (), identifier: Self.rootIdentifier)
    }

    fileprivate func instantiateViewController<S: Scene>(withPayload payload: S.InputType,
                                                         identifier: KeyPath<Self, S>) -> UIViewController {
        let scene = self[keyPath: identifier]
        let segues = scene.segues(inStoryboard: self)
        let (viewController, didUnwind) = scene.instantiate(withPayload: payload, segues: segues)
        segues.viewController = viewController

        let userInfo = ViewControllerUserInfo(identifier, didUnwind)

        viewControllerUserInfos.setObject(userInfo, forKey: viewController)

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

extension UIViewController {

    @objc
    public func allowedChildrenForUnwinding(from sourceViewController: UIViewController) -> [UIViewController] {
        return children.filter { $0 != sourceViewController }
    }

    @objc
    public func unwind(towards viewController: UIViewController) {
    }

    private func _unwind(towards viewController: UIViewController) {
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

    public var sampleInput: Void
    public var sampleUnwindingInput: Void

    public func instantiate(withPayload payload: Void, segues: SeguesContainer) -> (UITabBarController, didUnwind: UnwindingHandler<Void>) {
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

    public var sampleInput: Void
    public var sampleUnwindingInput: Void

    public func instantiate(withPayload payload: Void, segues: SeguesContainer) -> (UINavigationController, didUnwind: UnwindingHandler<Void>) {
        return (UINavigationController(rootViewController: loadRootViewController()), {_ in })
    }
}
