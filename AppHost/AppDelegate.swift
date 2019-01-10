import UIKit
import SDK

final class PAXStoryboard: Storyboard {

    static var rootIdentifier: KeyPath<PAXStoryboard, TabBarScene> = \.rootScene

    var rootScene: TabBarScene!
    var naviagtionSceneA0: NavigationScene!
    var sceneA0: StaticScene!
    var sceneA1: SampleScene!
    var sceneA2: SampleScene!
    var naviagtionSceneB0: NavigationScene!
    var sceneB0: StaticScene!
}

class RootViewControllerAssembly: Assembly {
    var rootViewController: UIViewController {
        return provide(instance: StoryboardAssembly().storyboard.instantiateRootViewController())
    }
}

class StoryboardAssembly: Assembly {
    var storyboard: PAXStoryboard {
        return provide(instance: PAXStoryboard()) { storyboard in

            storyboard.rootScene = TabBarScene(scenes: [
                storyboard.connection(to: \.naviagtionSceneA0),
                storyboard.connection(to: \.naviagtionSceneB0),
                ])

            storyboard.naviagtionSceneA0 = NavigationScene(rootScene: storyboard.connection(to: \.sceneA0))

            storyboard.sceneA0 = {
                let scene = SampleScene()
                scene.completionSegue = self.storyboard.segue(to: \.sceneA1, transition: PushSegue())
                return StaticScene(scene: scene, input: 1)
            }()

            storyboard.sceneA1 = {
                let scene = SampleScene()
                scene.completionSegue = self.storyboard.segue(to: \.sceneA2, transition: PushSegue())
                return scene
            }()

            storyboard.sceneA2 = {
                let scene = SampleScene()
                scene.completionSegue = self.storyboard.segue(to: \.sceneB0, transition: ActivationgSegue(), mapPayload: { (p: Int) in () })
                return scene
            }()

            storyboard.naviagtionSceneB0 = NavigationScene(rootScene: storyboard.connection(to: \.sceneB0))

            storyboard.sceneB0 = {
                let scene = SampleScene()
                scene.completionSegue = self.storyboard.segue(to: \.sceneA0, transition: ActivationgSegue(), mapPayload: { (p: Int) in () })
                return StaticScene(scene: scene, input: 10)
            }()
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

