import UIKit

public protocol Scene {
    associatedtype InputType
    func instantiateViewController(withPayload payload: InputType) -> UIViewController
}

public class Segue<InputType> {
    public func perform(withInput input: InputType, sourceViewController: UIViewController) {}
}

public class PushSegue<Destination: Scene> : Segue<Destination.InputType> {

    private let destination: Destination

    public init(destination: Destination) {
        self.destination = destination
    }

    override public func perform(withInput input: Destination.InputType, sourceViewController: UIViewController) {
        let viewController = destination.instantiateViewController(withPayload: input)
        sourceViewController.navigationController!.pushViewController(viewController, animated: true)
    }
}
