//
//  MainThreadValueWrapper.swift
//  ThreadSafe
//
//  Created by jiasong on 2024/12/11.
//

import Foundation

@propertyWrapper public final class MainThreadValueWrapper<Value> {
    
    public let projectedValue: MainThreadValueProjected<Value>
    
    public var wrappedValue: Value {
        get {
            return self.projectedValue.mainThread.value
        }
        set {
            self.projectedValue.mainThread.value = newValue
        }
    }
    
    public init(wrappedValue: Value) {
        self.projectedValue = MainThreadValueProjected(value: wrappedValue)
    }
    
}

public final class MainThreadValueProjected<Value> {
    
    fileprivate var mainThread: MainThreadValue<Value>
    
    fileprivate init(value: Value) {
        self.mainThread = MainThreadValue(value)
    }
    
}

extension MainThreadValueWrapper: CustomStringConvertible {
    
    public var description: String {
        return String(describing: self.projectedValue.mainThread)
    }
    
}
