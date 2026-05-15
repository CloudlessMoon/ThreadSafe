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

extension MainThreadValueWrapper: CustomStringConvertible {
    
    public var description: String {
        return String(describing: self.projectedValue.mainThread)
    }
    
}

public final class MainThreadValueProjected<Value> {
    
    fileprivate var mainThread: MainThreadValue<Value>
    
    fileprivate init(value: Value) {
        self.mainThread = MainThreadValue(value)
    }
    
}

extension MainThreadValueProjected {
    
    @discardableResult
    public func mutating(execute work: @MainActor (inout Value) throws -> Void) rethrows -> Value {
        return try self.mainThread.mutating(execute: work)
    }
    
    @discardableResult
    public func mutating<S>(state: S, execute work: @MainActor (S, inout Value) throws -> Void) rethrows -> Value {
        return try self.mainThread.mutating(state: state, execute: work)
    }
    
    public func currentOrAsyncMutating(execute work: @MainActor @escaping (inout Value) -> Void) {
        self.mainThread.currentOrAsyncMutating(execute: work)
    }
    
    public func currentOrAsyncMutating<S>(state: S, execute work: @MainActor @escaping (S, inout Value) -> Void) {
        self.mainThread.currentOrAsyncMutating(state: state, execute: work)
    }
    
    @discardableResult
    public func asyncMutating(execute work: @MainActor @escaping (inout Value) -> Void) -> DispatchWorkItem {
        return try self.mainThread.asyncMutating(execute: work)
    }
    
    @discardableResult
    public func asyncMutating<S>(state: S, execute work: @MainActor @escaping (S, inout Value) -> Void) -> DispatchWorkItem {
        return try self.mainThread.asyncMutating(state: state, execute: work)
    }
    
    @discardableResult
    public func asyncMutating(deadline: DispatchTime, execute work: @MainActor @escaping (inout Value) -> Void) -> DispatchWorkItem {
        return try self.mainThread.asyncMutating(deadline: deadline, execute: work)
    }
    
    @discardableResult
    public func asyncMutating<S>(state: S, deadline: DispatchTime, execute work: @MainActor @escaping (S, inout Value) -> Void) -> DispatchWorkItem {
        return try self.mainThread.asyncMutating(state: state, deadline: deadline, execute: work)
    }
    
}
