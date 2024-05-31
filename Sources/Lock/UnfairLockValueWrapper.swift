//
//  UnfairLockValueWrapper.swift
//  ThreadSafe
//
//  Created by jiasong on 2024/5/30.
//

import Foundation

@propertyWrapper public final class UnfairLockValueWrapper<Value> {
    
    public var wrappedValue: Value {
        get {
            return self.lock.value
        }
        set {
            self.lock.value = newValue
        }
    }
    
    private let lock: UnfairLockValue<Value>
    
    public init(wrappedValue: Value) {
        self.lock = UnfairLockValue(wrappedValue)
    }
    
}
