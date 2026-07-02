//
//  ReadWriteValueWrapper.swift
//  ThreadSafe
//
//  Created by jiasong on 2024/5/30.
//

import Foundation

@propertyWrapper public struct ReadWriteValueWrapper<Value> {
    
    public static subscript<EnclosingSelf: AnyObject>(
        _enclosingInstance object: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> Value {
        get {
            return object[keyPath: storageKeyPath].readWrite.value
        }
        set {
            object[keyPath: storageKeyPath].readWrite.value = newValue
        }
    }
    
    public var projectedValue: ReadWriteValueProjected<Value> {
        return ReadWriteValueProjected(self.readWrite)
    }
    
    @available(*, unavailable, message: "@ReadWriteValueWrapper is only available on properties of classes")
    public var wrappedValue: Value {
        get { fatalError() }
        nonmutating set { fatalError() }
    }
    
    private let readWrite: ReadWriteValue<Value>
    
    public init(wrappedValue: Value, task: ReadWriteTask = .init(label: "com.cloudlessmoon.thread-safe.read-write-value-wrapper")) {
        self.readWrite = ReadWriteValue(wrappedValue, task: task)
    }
    
}

extension ReadWriteValueWrapper: CustomStringConvertible {
    
    public var description: String {
        return String(describing: self.readWrite)
    }
    
}

public struct ReadWriteValueProjected<Value> {
    
    public var task: ReadWriteTask {
        get {
            return self.readWrite.task
        }
        set {
            self.readWrite.task = newValue
        }
    }
    
    private let readWrite: ReadWriteValue<Value>
    
    fileprivate init(_ readWrite: ReadWriteValue<Value>) {
        self.readWrite = readWrite
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
        return self.readWrite.asyncMutating(execute: work)
    }
    
    @discardableResult
    public func asyncMutating<S>(state: S, execute work: @escaping (S, inout Value) -> Void) -> ReadWriteTask.AsyncToken {
        return self.readWrite.asyncMutating(state: state, execute: work)
    }
    
    @discardableResult
    public func asyncMutating(deadline: DispatchTime, execute work: @escaping (inout Value) -> Void) -> ReadWriteTask.AsyncToken {
        return self.readWrite.asyncMutating(deadline: deadline, execute: work)
    }
    
    @discardableResult
    public func asyncMutating<S>(state: S, deadline: DispatchTime, execute work: @escaping (S, inout Value) -> Void) -> ReadWriteTask.AsyncToken {
        return self.readWrite.asyncMutating(state: state, deadline: deadline, execute: work)
    }
    
}
