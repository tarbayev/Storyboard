import UIKit
import SDK

class StoryboardAssembly: Assembly {

    var rootScene: TabBarScene {
        return provide(instance: TabBarScene(scenes: [
            naviagtionSceneA0,
            naviagtionSceneB0,
        ]))
    }
}

private extension StoryboardAssembly {
    var naviagtionSceneA0: NavigationScene {
        return provide(instance: NavigationScene(rootScene: StaticScene(scene: sceneA0, input: 1)))
    }

    var sceneA0: SampleScene {
        return provide(instance: SampleScene(), complete: { scene in
            scene.completionSegue = PushSegue(destination: self.sceneA1)
        })
    }

    var sceneA1: SampleScene {
        return provide(instance: SampleScene(), complete: { scene in
            scene.completionSegue = PushSegue(destination: self.sceneA2)
        })
    }

    var sceneA2: SampleScene {
        return provide(instance: SampleScene(), complete: { scene in
            scene.completionSegue = ActivationgSegue(destination: self.sceneB0)
        })
    }

    var naviagtionSceneB0: NavigationScene {
        return provide(instance: NavigationScene(rootScene: StaticScene(scene: sceneB0, input: 1)))
    }

    var sceneB0: SampleScene {
        return provide(instance: SampleScene(), complete: { scene in
            scene.completionSegue = PushSegue(destination: self.sceneA0)
        })
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

        window?.rootViewController = StoryboardAssembly().rootScene.instantiateViewController(withPayload: ())
        window?.makeKeyAndVisible()
        return true
    }
}

