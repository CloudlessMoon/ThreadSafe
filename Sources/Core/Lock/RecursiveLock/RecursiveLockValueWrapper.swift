//
//  RecursiveLockValueWrapper.swift
//  ThreadSafe
//
//  Created by jiasong on 2026/6/29.
//

import Foundation

@propertyWrapper public struct RecursiveLockValueWrapper<Value> {
    
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
    
    public var projectedValue: RecursiveLockValueProjected<Value> {
        return RecursiveLockValueProjected(self.lock)
    }
    
    @available(*, unavailable, message: "the propertyWrapper is only available on properties of classes")
    public var wrappedValue: Value {
        get { fatalError() }
        nonmutating set { fatalError() }
    }
    
    private let lock: RecursiveLockValue<Value>
    
    public init(wrappedValue: Value) {
        self.lock = RecursiveLockValue(wrappedValue)
    }
    
}

extension RecursiveLockValueWrapper: CustomStringConvertible {
    
    public var description: String {
        return String(describing: self.lock)
    }
    
}

public struct RecursiveLockValueProjected<Value> {
    
    private let lock: RecursiveLockValue<Value>
    
    fileprivate init(_ lock: RecursiveLockValue<Value>) {
        self.lock = lock
    }
    
}

extension RecursiveLockValueProjected {
    
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
