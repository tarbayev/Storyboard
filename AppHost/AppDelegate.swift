import UIKit
import SDK

final class PAXStoryboard: Storyboard {
    static var rootIdentifier: KeyPath<PAXStoryboard, TabBarScene> = \.rootScene

    lazy var rootScene: TabBarScene = TabBarScene(scenes: [
        connection(to: \.naviagtionSceneA0),
        connection(to: \.naviagtionSceneB0),
        ])

    lazy var naviagtionSceneA0: NavigationScene = NavigationScene(rootScene: connection(to: \.sceneA0, payload: 1))
    lazy var naviagtionSceneB0: NavigationScene = NavigationScene(rootScene: connection(to: \.sceneB0, payload: 10))

    var sceneA0: SampleScene!
    var sceneA1: SampleScene!
    var sceneA2: SampleScene!

    var sceneB0: SampleScene!

    func wireUp() {
        sceneA0.completionSegue = segue(to: \.sceneA1, transition: PushSegue())

        sceneA1.completionSegue = segue(to: \.sceneA2, transition: PushSegue())

        sceneA2.completionSegue = segue(to: \.sceneB0, transition: ActivationgSegue())

        sceneB0.completionSegue = segue(to: \.sceneA0, transition: ActivationgSegue())
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

