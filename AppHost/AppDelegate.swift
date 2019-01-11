import UIKit
import SDK

final class PAXStoryboard: Storyboard {
    static var rootIdentifier: KeyPath<PAXStoryboard, TabBarScene> = \.rootScene

    lazy var rootScene = TabBarScene(scenes: [
        connection(to: \.naviagtionSceneA0),
        connection(to: \.naviagtionSceneB0),
        ])

    lazy var naviagtionSceneA0 = NavigationScene(rootScene: connection(to: \.sceneA0, payload: 1))
    lazy var naviagtionSceneB0 = NavigationScene(rootScene: connection(to: \.sceneB0, payload: 10))

    var sceneA0: SampleScene!
    var sceneA1: SampleScene!
    var sceneA2: SampleScene!

    var sceneB0: SampleScene!

    func wireUp() {

        connect(sceneA0) { c in
            c.connect(\.completionSegue, to: \.sceneA1, transition: PushTransition())
        }

        connect(sceneA1) { c in
            c.connect(\.completionSegue, to: \.sceneA2, transition: PushTransition())
        }

        connect(sceneA2) { c in
            c.connect(\.completionSegue, to: \.sceneB0, transition: ActivationgTransition())
        }

        connect(sceneB0) { c in
            c.connect(\.completionSegue, to: \.sceneA0, transition: ActivationgTransition())
        }
    }
}

class RootViewControllerAssembly: Assembly {
    var rootViewController: UIViewController {
        return provide(instance: StoryboardAssembly().storyboard.instantiateRootViewController())
    }
}

class StoryboardAssembly: Assembly {
    var storyboard: PAXStoryboard {
        return provide(instance: PAXStoryboard()) { storyboard in

            storyboard.sceneA0 = SampleScene()
            storyboard.sceneA1 = SampleScene()
            storyboard.sceneA2 = SampleScene()

            storyboard.sceneB0 = SampleScene()
        }
    }

}

//class StoryboardAssembly: Assembly {
//    func assemble(container: Container) {
//        container.register(HomeScene.self) { r in
//            return HomeScene()
//        }
//            .initCompleted { r, scene in
//                scene.showDetails = PushSegue(destination: r.resolve(DetailScene.self)!)
//        }
//        container.register(DetailScene.self) { r in
//            return DetailScene()
//        }
//        container.register(PushSegue<DetailScene>.self) { r in
//            return PushSegue(destination: r.resolve(DetailScene.self)!)
//        }
//    }
//}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow? = UIWindow()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

//        let assembler = Assembler([StoryboardAssembly()])
//        let homeScene = assembler.resolver.resolve(HomeScene.self)!

        window?.rootViewController = RootViewControllerAssembly().rootViewController
        window?.makeKeyAndVisible()
        return true
    }
}

