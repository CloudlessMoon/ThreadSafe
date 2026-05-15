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
            return self.task.read {
                return self._value
            }
        }
        set {
            self.task.write {
                self._value = newValue
            }
        }
    }
    
    @UnfairLockValueWrapper
    public var task: ReadWriteTask
    
    public init(_ value: Value, task: ReadWriteTask = .init(label: "com.cloudlessmoon.thread-safe.read-write-value")) {
        self._value = value
        self.task = task
    }
    
}

extension ReadWriteValue {
    
    @discardableResult
    public func mutating(execute work: (inout Value) throws -> Void) rethrows -> Value {
        return try self.task.write {
            try work(&self._value)
            return self._value
        }
    }
    
    @discardableResult
    public func mutating<S>(state: S, execute work: (S, inout Value) throws -> Void) rethrows -> Value {
        return try self.task.write(state: state) {
            try work($0, &self._value)
            return self._value
        }
    }
    
    @discardableResult
    public func asyncMutating(execute work: @escaping (inout Value) -> Void) -> ReadWriteTask.AsyncToken {
        return try self.task.asyncWrite {
            work(&self._value)
        }
    }
    
    @discardableResult
    public func asyncMutating<S>(state: S, execute work: @escaping (S, inout Value) -> Void) -> ReadWriteTask.AsyncToken {
        return try self.task.asyncWrite(state: state) {
            work($0, &self._value)
        }
    }
    
    @discardableResult
    public func asyncMutating(deadline: DispatchTime, execute work: @escaping (inout Value) -> Void) -> ReadWriteTask.AsyncToken {
        return self.task.asyncWriteAfter(deadline: deadline) {
            work(&self._value)
        }
    }
    
    @discardableResult
    public func asyncMutating<S>(state: S, deadline: DispatchTime, execute work: @escaping (S, inout Value) -> Void) -> ReadWriteTask.AsyncToken {
        return self.task.asyncWriteAfter(state: state, deadline: deadline) {
            work($0, &self._value)
        }
    }
    
}

extension ReadWriteValue: CustomStringConvertible {
    
    public var description: String {
        return String(describing: self.value)
    }
    
}
