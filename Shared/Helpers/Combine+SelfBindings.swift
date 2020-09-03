import Combine


/// Convenience extensions for Combine, adding memory-save bindings and Cancellable management.
/// Also published here: https://gist.github.com/frankschlegel/843a8c222520bf5c9f1ce812a7e750cb


/// Classes implementing this protocol can be target of convenience Publisher
/// bindings and assignments without causing accidental retain cycles.
/// Those bindings and assignments are also released together with the target.
///
/// For example:
///
///     aPublisher.bind(to: self) { me, object in
///         me.doSomething(with: object)
///     }
///
///     aPublisher.assign(to: \.property, on: self)
///
public protocol SelfBindable: AnyObject {

    /// A "bag" to store subscriptions in that should be cancelled
    /// when `self` is deallocated.
    var cancellables: Set<AnyCancellable> { get set }

}

extension Publisher {

    /// "Binds" the publisher to the target, i.e. the target receives values and completion events
    /// and ensures that the subscription is cancelled with the target is deallocated.
    /// - Parameters:
    ///   - target: The target object to bind the publisher to.
    ///   - receiveCompletion: The closure to execute on completion. The first parameter is the binding target.
    ///   - receiveValue: The closure to execute on receipt of a value. The first parameter is the binding target.
    public func bind<Target: SelfBindable>(to target: Target, receiveCompletion: @escaping (Target, Subscribers.Completion<Self.Failure>) -> Void, receiveValue: @escaping (Target, Self.Output) -> Void) {
        self.sink(receiveCompletion: { [weak target] completion in
            if let target = target { receiveCompletion(target, completion) }
        }, receiveValue: { [weak target] element in
            if let target = target { receiveValue(target, element) }
        }).store(in: &target.cancellables)
    }

}

extension Publisher where Self.Failure == Never {

    /// "Binds" the publisher to the target, i.e. the target receives values events
    /// and ensures that the subscription is cancelled with the target is deallocated.
    /// - Parameters:
    ///   - target: The target object to bind the publisher to.
    ///   - receiveValue: The closure to execute on receipt of a value. The first parameter is the binding target.
    public func bind<Target: SelfBindable>(to target: Target, receiveValue: @escaping (Target, Self.Output) -> Void) {
        self.sink { [weak target] element in
            if let target = target { receiveValue(target, element) }
        }.store(in: &target.cancellables)
    }

    /// Assigns each element from a publisher to a property on an object.
    /// The subscription created this way is cancelled when the target is deallocated.
    /// Using this method will also _not_ create any reference cycle between the subscription and the target.
    /// - Parameters:
    ///   - keyPath: A key path that indicates the property to assign.
    ///   - target: The object that contains the property. The subscriber assigns the object’s property every time it receives a new value.
    public func assign<Target: SelfBindable>(to keyPath: ReferenceWritableKeyPath<Target, Self.Output>, on target: Target) {
        self.sink { [weak target] element in
            target?[keyPath: keyPath] = element
        }.store(in: &target.cancellables)
    }

}

extension Publisher where Self.Output == Void {

    /// "Binds" the publisher to the target, i.e. the target receives values and completion events
    /// and ensures that the subscription is cancelled with the target is deallocated.
    /// - Parameters:
    ///   - target: The target object to bind the publisher to.
    ///   - receiveCompletion: The closure to execute on completion. The first parameter is the binding target.
    ///   - receiveValue: The closure to execute on receipt of a value. The parameter is the binding target.
    public func bind<Target: SelfBindable>(to target: Target, receiveCompletion: @escaping (Target, Subscribers.Completion<Self.Failure>) -> Void, receiveValue: @escaping (Target) -> Void) {
        self.sink(receiveCompletion: { [weak target] completion in
            if let target = target { receiveCompletion(target, completion) }
        }, receiveValue: { [weak target] in
            if let target = target { receiveValue(target) }
        }).store(in: &target.cancellables)
    }

}

extension Publisher where Self.Output == Void, Self.Failure == Never {

    /// "Binds" the publisher to the target, i.e. the target receives values events
    /// and ensures that the subscription is cancelled with the target is deallocated.
    /// - Parameters:
    ///   - target: The target object to bind the publisher to.
    ///   - receiveValue: The closure to execute on receipt of a value. The parameter is the binding target.
    public func bind<Target: SelfBindable>(to target: Target, receiveValue: @escaping (Target) -> Void) {
        self.sink { [weak target] in
            if let target = target { receiveValue(target) }
        }.store(in: &target.cancellables)
    }

}


#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)

import ObjectiveC.runtime


/// Extends `NSObject` to provide a `cancellables` Set via associated objects,
/// so that any `NSObject` subtype can be target of self-binding API above.
extension NSObject: SelfBindable {

    private struct AssociatedKeys {
        static var CancellablesKey = "CancellablesKey"
    }

    /// Helper for wrapping the ``Set<AnyCancellable>`` into an (associated) object.
    private final class Wrapped<T> {
        let value: T
        init(_ x: T) {
            value = x
        }
    }

    public var cancellables: Set<AnyCancellable> {
        get {
            if let cancellables = objc_getAssociatedObject(self, &NSObject.AssociatedKeys.CancellablesKey) as? Wrapped<Set<AnyCancellable>> {
                return cancellables.value
            } else {
                let cancellables = Set<AnyCancellable>()
                objc_setAssociatedObject(self, &NSObject.AssociatedKeys.CancellablesKey, Wrapped(cancellables), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return cancellables
            }
        }
        set {
            objc_setAssociatedObject(self, &NSObject.AssociatedKeys.CancellablesKey, Wrapped(newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

#endif
