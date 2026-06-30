//
//  RecursiveLockValueWrapper.swift
//  ThreadSafe
//
//  Created by jiasong on 2026/6/29.
//

import Foundation

@propertyWrapper public final class RecursiveLockValueWrapper<Value> {
    
    public let projectedValue: RecursiveLockValueProjected<Value>
    
    public var wrappedValue: Value {
        get {
            return self.projectedValue.lock.value
        }
        set {
            self.projectedValue.lock.value = newValue
        }
    }
    
    public init(wrappedValue: Value) {
        self.projectedValue = RecursiveLockValueProjected(value: wrappedValue)
    }
    
}

extension RecursiveLockValueWrapper: CustomStringConvertible {
    
    public var description: String {
        return String(describing: self.projectedValue.lock.value)
    }
    
}

public final class RecursiveLockValueProjected<Value> {
    
    fileprivate let lock: RecursiveLockValue<Value>
    
    fileprivate init(value: Value) {
        self.lock = RecursiveLockValue(value)
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
