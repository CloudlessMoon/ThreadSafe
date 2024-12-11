//
//  MainThreadValue.swift
//  ThreadSafe
//
//  Created by jiasong on 2024/12/11.
//

import Foundation

public final class MainThreadValue<Value> {
    
    private var _value: Value
    public var value: Value {
        get {
            return self.task.sync { self._value }
        }
        set {
            self.task.sync { self._value = newValue }
        }
    }
    
    private let task = MainThreadTask()
    
    public init(_ value: Value) {
        self._value = value
    }
    
}

extension MainThreadValue: CustomStringConvertible {
    
    public var description: String {
        return String(describing: self.value)
    }
    
}
