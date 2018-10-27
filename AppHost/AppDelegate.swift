import UIKit
import SDK

class StoryboardAssembly: Assembly {

    var homeScene: HomeScene {
        return provide(instance: HomeScene(), complete: { scene in
            scene.showDetails = PushSegue(destination: self.detailScene)
        })
    }

    private var detailScene: DetailScene {
        return provide(instance: DetailScene())
    }

    private var pushSegue: PushSegue<DetailScene> {
        return provide(instance: PushSegue(destination: detailScene))
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

        let homeScene = StoryboardAssembly().homeScene

        let navigationViewController = UINavigationController(rootViewController: homeScene.instantiateViewController(withPayload: ()))

        window?.rootViewController = navigationViewController
        window?.makeKeyAndVisible()
        return true
    }
}

