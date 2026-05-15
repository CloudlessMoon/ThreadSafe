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
            return self.task.sync {
                return self._value
            }
        }
        set {
            self.task.sync {
                self._value = newValue
            }
        }
    }
    
    private let task = MainThreadTask.default
    
    public init(_ value: Value) {
        self._value = value
    }
    
}

extension MainThreadValue {
    
    @discardableResult
    public func mutating(execute work: @MainActor (inout Value) throws -> Void) rethrows -> Value {
        return try self.task.sync {
            try work(&self._value)
            return self._value
        }
    }
    
    @discardableResult
    public func mutating<S>(state: S, execute work: @MainActor (S, inout Value) throws -> Void) rethrows -> Value {
        return try self.task.sync(state: state) {
            try work($0, &self._value)
            return self._value
        }
    }
    
    public func currentOrAsyncMutating(execute work: @MainActor @escaping (inout Value) -> Void) {
        self.task.currentOrAsync {
            work(&self._value)
        }
    }
    
    public func currentOrAsyncMutating<S>(state: S, execute work: @MainActor @escaping (S, inout Value) -> Void) {
        self.task.currentOrAsync(state: state) {
            work($0, &self._value)
        }
    }
    
    @discardableResult
    public func asyncMutating(execute work: @MainActor @escaping (inout Value) -> Void) -> DispatchWorkItem {
        return try self.task.async {
            work(&self._value)
        }
    }
    
    @discardableResult
    public func asyncMutating<S>(state: S, execute work: @MainActor @escaping (S, inout Value) -> Void) -> DispatchWorkItem {
        return try self.task.async(state: state) {
            work($0, &self._value)
        }
    }
    
    @discardableResult
    public func asyncMutating(deadline: DispatchTime, execute work: @MainActor @escaping (inout Value) -> Void) -> DispatchWorkItem {
        return self.task.asyncAfter(deadline: deadline) {
            work(&self._value)
        }
    }
    
    @discardableResult
    public func asyncMutating<S>(state: S, deadline: DispatchTime, execute work: @MainActor @escaping (S, inout Value) -> Void) -> DispatchWorkItem {
        return self.task.asyncAfter(state: state, deadline: deadline) {
            work($0, &self._value)
        }
    }
    
}

extension MainThreadValue: CustomStringConvertible {
    
    public var description: String {
        return String(describing: self.value)
    }
    
}
