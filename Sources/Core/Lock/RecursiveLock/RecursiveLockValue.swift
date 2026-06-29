//
//  RecursiveLockValue.swift
//  ThreadSafe
//
//  Created by jiasong on 2026/6/29.
//

import Foundation

public final class RecursiveLockValue<Value> {
    
    private var _value: Value
    public var value: Value {
        get {
            return self.lock.withLock {
                return self._value
            }
        }
        set {
            self.lock.withLock {
                self._value = newValue
            }
        }
    }
    
    private let lock: RecursiveLock
    
    public init(_ value: Value) {
        self._value = value
        self.lock = RecursiveLock()
    }
    
}

extension RecursiveLockValue {
    
    @discardableResult
    public func mutating(execute work: (inout Value) throws -> Void) rethrows -> Value {
        return try self.lock.withLock {
            try work(&self._value)
            return self._value
        }
    }
    
    @discardableResult
    public func mutating<S>(state: S, execute work: (S, inout Value) throws -> Void) rethrows -> Value {
        return try self.lock.withLock(state: state) {
            try work($0, &self._value)
            return self._value
        }
    }
    
}

extension RecursiveLockValue: CustomStringConvertible {
    
    public var description: String {
        return String(describing: self.value)
    }
    
}
