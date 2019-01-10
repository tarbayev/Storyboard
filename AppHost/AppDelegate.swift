import UIKit
import SDK

class PAXStoryboard: Storyboard {
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
        return provide(instance: StoryboardAssembly().storyboard.instantiateViewController(withPayload: (), identifier: \.rootScene))
    }
}

class StoryboardAssembly: Assembly {
    var storyboard: PAXStoryboard {
        return provide(instance: PAXStoryboard()) { storyboard in
            storyboard.rootScene = self.rootScene
            storyboard.naviagtionSceneA0 = self.naviagtionSceneA0
            storyboard.sceneA0 = self.sceneA0
            storyboard.sceneA1 = self.sceneA1
            storyboard.sceneA2 = self.sceneA2
            storyboard.naviagtionSceneB0 = self.naviagtionSceneB0
            storyboard.sceneB0 = self.sceneB0
        }
    }

}

private extension StoryboardAssembly {

    var rootScene: TabBarScene {
        return provide(instance: TabBarScene(scenes: [
            storyboard.connection(to: \.naviagtionSceneA0),
            storyboard.connection(to: \.naviagtionSceneB0),
            ]))
    }

    var naviagtionSceneA0: NavigationScene {
        return provide(instance: NavigationScene(rootScene: storyboard.connection(to: \.sceneA0)))
    }

    var sceneA0: StaticScene {
        let scene = SampleScene()
        scene.completionSegue = self.storyboard.segue(to: \.sceneA1, transition: PushSegue())
        return provide(instance: StaticScene(scene: scene, input: 1))
    }

    var sceneA1: SampleScene {
        return provide(instance: SampleScene(), complete: { scene in
            scene.completionSegue = self.storyboard.segue(to: \.sceneA2, transition: PushSegue())
        })
    }

    var sceneA2: SampleScene {
        return provide(instance: SampleScene(), complete: { scene in
            scene.completionSegue = self.storyboard.segue(to: \.sceneB0, transition: ActivationgSegue(), mapPayload: { (p: Int) in () })
        })
    }

    var naviagtionSceneB0: NavigationScene {
        return provide(instance: NavigationScene(rootScene: storyboard.connection(to: \.sceneB0)))
    }

    var sceneB0: StaticScene {
        let scene = SampleScene()
        scene.completionSegue = self.storyboard.segue(to: \.sceneA0, transition: ActivationgSegue(), mapPayload: { (p: Int) in () })
        return provide(instance: StaticScene(scene: scene, input: 10))
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

