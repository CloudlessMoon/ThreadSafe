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
            self.projectedValue.readWrite.value
        }
        set {
            self.projectedValue.readWrite.value = newValue
        }
    }
    
    public init(wrappedValue: Value, label: String? = nil) {
        self.projectedValue = ReadWriteValueProjected(value: wrappedValue, label: label)
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
    
    fileprivate init(value: Value, label: String?) {
        let label = label ?? "com.jiasong.thread-safe.read-write-value"
        self.readWrite = ReadWriteValue(value, label: label)
    }
    
}
