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
    
    public init(wrappedValue: Value, task: ReadWriteTask = .init(label: "com.cloudlessmoon.thread-safe.read-write-value-wrapper")) {
        self.projectedValue = ReadWriteValueProjected(value: wrappedValue, task: task)
    }
    
}

extension ReadWriteValueWrapper: CustomStringConvertible {
    
    public var description: String {
        return String(describing: self.projectedValue.readWrite)
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
    
    fileprivate init(value: Value, task: ReadWriteTask) {
        self.readWrite = ReadWriteValue(value, task: task)
    }
    
}

extension ReadWriteValueProjected {
    
    @discardableResult
    public func mutating(execute work: (inout Value) throws -> Void) rethrows -> Value {
        return try self.readWrite.mutating(execute: work)
    }
    
    @discardableResult
    public func mutating<S>(state: S, execute work: (S, inout Value) throws -> Void) rethrows -> Value {
        return try self.readWrite.mutating(state: state, execute: work)
    }
    
    @discardableResult
    public func asyncMutating(execute work: @escaping (inout Value) -> Void) -> ReadWriteTask.AsyncToken {
        return try self.readWrite.asyncMutating(execute: work)
    }
    
    @discardableResult
    public func asyncMutating<S>(state: S, execute work: @escaping (S, inout Value) -> Void) -> ReadWriteTask.AsyncToken {
        return try self.readWrite.asyncMutating(state: state, execute: work)
    }
    
    @discardableResult
    public func asyncMutating(deadline: DispatchTime, execute work: @escaping (inout Value) -> Void) -> ReadWriteTask.AsyncToken {
        return try self.readWrite.asyncMutating(deadline: deadline, execute: work)
    }
    
    @discardableResult
    public func asyncMutating<S>(state: S, deadline: DispatchTime, execute work: @escaping (S, inout Value) -> Void) -> ReadWriteTask.AsyncToken {
        return try self.readWrite.asyncMutating(state: state, deadline: deadline, execute: work)
    }
    
}
