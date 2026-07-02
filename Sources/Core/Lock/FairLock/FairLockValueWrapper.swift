//
//  FairLockValueWrapper.swift
//  ThreadSafe
//
//  Created by jiasong on 2026/6/29.
//

import Foundation

@propertyWrapper public struct FairLockValueWrapper<Value> {
    
    public static subscript<EnclosingSelf: AnyObject>(
        _enclosingInstance object: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> Value {
        get {
            return object[keyPath: storageKeyPath].lock.value
        }
        set {
            object[keyPath: storageKeyPath].lock.value = newValue
        }
    }
    
    public var projectedValue: FairLockValueProjected<Value> {
        return FairLockValueProjected(self.lock)
    }
    
    @available(*, unavailable, message: "@FairLockValueWrapper is only available on properties of classes")
    public var wrappedValue: Value {
        get { fatalError() }
        nonmutating set { fatalError() }
    }
    
    private let lock: FairLockValue<Value>
    
    public init(wrappedValue: Value) {
        self.lock = FairLockValue(wrappedValue)
    }
    
}

extension FairLockValueWrapper: CustomStringConvertible {
    
    public var description: String {
        return String(describing: self.lock)
    }
    
}

public struct FairLockValueProjected<Value> {
    
    private let lock: FairLockValue<Value>
    
    fileprivate init(_ lock: FairLockValue<Value>) {
        self.lock = lock
    }
    
}

extension FairLockValueProjected {
    
    @discardableResult
    public func mutating(execute work: (inout Value) throws -> Void) rethrows -> Value {
        return try self.lock.mutating(execute: work)
    }
    
    @discardableResult
    public func mutating<T>(execute work: (inout Value) throws -> T) rethrows -> T {
        return try self.lock.mutating(execute: work)
    }
    
    @discardableResult
    public func mutating<S>(state: S, execute work: (S, inout Value) throws -> Void) rethrows -> Value {
        return try self.lock.mutating(state: state, execute: work)
    }
    
    @discardableResult
    public func mutating<S, T>(state: S, execute work: (S, inout Value) throws -> T) rethrows -> T {
        return try self.lock.mutating(state: state, execute: work)
    }
    
}
