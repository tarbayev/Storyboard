import ObjectiveC

public protocol AssemblyAwakable {
    func awakeFromAssembly()
}

open class Assembly {
    private var rootKey: String!
    private var instances: [String:Any] = [:]
    private var completers: [() -> ()] = []
    private var stackDepth: Int = 0

    private static var RetainedKey: Int = 0

    public init() {}

    public func provide<T>(instance: @autoclosure () -> T, forKey: String = #function, complete: @escaping (T) -> Void = {_ in }) -> T {

        if let object = instances[forKey] {
            return object as! T
        }

        if stackDepth == 0 {
            rootKey = forKey
        }

        stackDepth += 1

        let object = instance()

        instances[forKey] = object

        completers.append {
            complete(object)

            if let awakable = object as? AssemblyAwakable {
                awakable.awakeFromAssembly()
            }
        }

        stackDepth -= 1

        if stackDepth == 0 {
            completers.forEach { complete in
                complete()
            }

            instances.removeValue(forKey: rootKey)
            objc_setAssociatedObject(object, &Assembly.RetainedKey, instances.values, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            instances.removeAll()
        }

        return object
    }

    public func register<T>(external: T, forKey: String = #function) {
        instances[forKey] = external
    }

    public func external<T>(forKey: String = #function) -> T {
        return instances[forKey] as! T
    }
}

