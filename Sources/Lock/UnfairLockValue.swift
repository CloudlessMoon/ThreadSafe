//
//  UnfairLockValue.swift
//  ThreadSafe
//
//  Created by jiasong on 2024/5/30.
//

import Foundation

public final class UnfairLockValue<Value> {
    
    private var _value: Value
    public var value: Value {
        get {
            return self.lock.withLock { self._value }
        }
        set {
            self.lock.withLock { self._value = newValue }
        }
    }
    
    private let lock: UnfairLock
    
    public init(_ value: Value) {
        self._value = value
        self.lock = UnfairLock()
    }
    
}

extension UnfairLockValue: CustomStringConvertible {
    
    public var description: String {
        return String(describing: self.value)
    }
    
}
