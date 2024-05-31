//
//  ReadWriteValue.swift
//  ThreadSafe
//
//  Created by jiasong on 2024/5/30.
//

import Foundation

public final class ReadWriteValue<Value> {
    
    private var _value: Value
    public var value: Value {
        get {
            return self.task.read { self._value }
        }
        set {
            self.task.write { self._value = newValue }
        }
    }
    
    @UnfairLockValueWrapper
    public var task: ReadWriteTask
    
    public init(_ value: Value, task: ReadWriteTask = .init(label: "com.jiasong.thread-safe.read-write-value")) {
        self._value = value
        self.task = task
    }
    
}

extension ReadWriteValue: CustomStringConvertible {
    
    public var description: String {
        return String(describing: self.value)
    }
    
}
