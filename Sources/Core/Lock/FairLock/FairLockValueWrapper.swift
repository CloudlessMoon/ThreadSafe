//
//  FairLockValueWrapper.swift
//  ThreadSafe
//
//  Created by jiasong on 2026/6/29.
//

import Foundation

@propertyWrapper public final class FairLockValueWrapper<Value> {
    
    public let projectedValue: FairLockValueProjected<Value>
    
    public var wrappedValue: Value {
        get {
            return self.projectedValue.lock.value
        }
        set {
            self.projectedValue.lock.value = newValue
        }
    }
    
    public init(wrappedValue: Value) {
        self.projectedValue = FairLockValueProjected(value: wrappedValue)
    }
    
}

extension FairLockValueWrapper: CustomStringConvertible {
    
    public var description: String {
        return String(describing: self.projectedValue.lock.value)
    }
    
}

public final class FairLockValueProjected<Value> {
    
    fileprivate let lock: FairLockValue<Value>
    
    fileprivate init(value: Value) {
        self.lock = FairLockValue(value)
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
