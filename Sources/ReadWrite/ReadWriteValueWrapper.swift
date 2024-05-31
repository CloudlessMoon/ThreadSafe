//
//  ReadWriteValueWrapper.swift
//  ThreadSafe
//
//  Created by jiasong on 2024/5/30.
//

import Foundation

@propertyWrapper public final class ReadWriteValueWrapper<Value> {
    
    public let projectedValue: ReadWriteValueProjected<Value>
    
    public var wrappedValue: Value {
        get {
            return self.projectedValue.readWrite.value
        }
        set {
            self.projectedValue.readWrite.value = newValue
        }
    }
    
    public init(wrappedValue: Value, taskLabel: String? = nil) {
        self.projectedValue = ReadWriteValueProjected(value: wrappedValue, taskLabel: taskLabel)
    }
    
}

public final class ReadWriteValueProjected<Value> {
    
    public var task: ReadWriteTask {
        get {
            return self.readWrite.task
        }
        set {
            self.readWrite.task = newValue
        }
    }
    
    fileprivate var readWrite: ReadWriteValue<Value>
    
    fileprivate init(value: Value, taskLabel: String?) {
        self.readWrite = ReadWriteValue(value, taskLabel: taskLabel ?? "com.jiasong.thread-safe.read-write-value")
    }
    
}

extension ReadWriteValueWrapper: CustomStringConvertible {
    
    public var description: String {
        return String(describing: self.projectedValue.readWrite)
    }
    
}
