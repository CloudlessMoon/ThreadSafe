//
//  ReadWriteValueWrapper.swift
//  ThreadSafe
//
//  Created by jiasong on 2024/5/30.
//

import Foundation

@propertyWrapper public final class ReadWriteValueWrapper<Value> {
    
    public var wrappedValue: Value {
        get {
            self.readWriteValue.value
        }
        set {
            self.readWriteValue.value = newValue
        }
    }
    
    private let readWriteValue: ReadWriteValue<Value>
    
    public init(wrappedValue: Value) {
        self.readWriteValue = ReadWriteValue(label: "com.jiasong.thread-safe.read-write-value", value: wrappedValue)
    }
    
}
