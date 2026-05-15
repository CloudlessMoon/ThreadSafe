//
//  UnfairLockValueWrapper.swift
//  ThreadSafe
//
//  Created by jiasong on 2024/5/30.
//

import Foundation

@propertyWrapper public final class UnfairLockValueWrapper<Value> {
    
    public let projectedValue: UnfairLockValueProjected<Value>
    
    public var wrappedValue: Value {
        get {
            return self.projectedValue.lock.value
        }
        set {
            self.projectedValue.lock.value = newValue
        }
    }
    
    public init(wrappedValue: Value) {
        self.projectedValue = UnfairLockValueProjected(value: wrappedValue)
    }
    
}

extension UnfairLockValueWrapper: CustomStringConvertible {
    
    public var description: String {
        return String(describing: self.projectedValue.lock.value)
    }
    
}

public final class UnfairLockValueProjected<Value> {
    
    fileprivate let lock: UnfairLockValue<Value>
    
    fileprivate init(value: Value) {
        self.lock = UnfairLockValue(value)
    }
    
}

extension UnfairLockValueProjected {
    
    @discardableResult
    public func mutating(execute work: (inout Value) throws -> Void) rethrows -> Value {
        return try self.lock.mutating(execute: work)
    }
    
    @discardableResult
    public func mutating<S>(state: S, execute work: (S, inout Value) throws -> Void) rethrows -> Value {
        return try self.lock.mutating(state: state, execute: work)
    }
    
}
