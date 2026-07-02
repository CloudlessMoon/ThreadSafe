//
//  MainThreadValueWrapper.swift
//  ThreadSafe
//
//  Created by jiasong on 2024/12/11.
//

import Foundation

@propertyWrapper public struct MainThreadValueWrapper<Value> {
    
    public static subscript<EnclosingSelf: AnyObject>(
        _enclosingInstance object: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> Value {
        get {
            return object[keyPath: storageKeyPath].mainThread.value
        }
        set {
            object[keyPath: storageKeyPath].mainThread.value = newValue
        }
    }
    
    public var projectedValue: MainThreadValueProjected<Value> {
        return MainThreadValueProjected(self.mainThread)
    }
    
    @available(*, unavailable, message: "@MainThreadValueWrapper is only available on properties of classes")
    public var wrappedValue: Value {
        get { fatalError() }
        nonmutating set { fatalError() }
    }
    
    private let mainThread: MainThreadValue<Value>
    
    public init(wrappedValue: Value) {
        self.mainThread = MainThreadValue(wrappedValue)
    }
    
}

extension MainThreadValueWrapper: CustomStringConvertible {
    
    public var description: String {
        return String(describing: self.mainThread)
    }
    
}

public struct MainThreadValueProjected<Value> {
    
    private let mainThread: MainThreadValue<Value>
    
    fileprivate init(_ mainThread: MainThreadValue<Value>) {
        self.mainThread = mainThread
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
        return self.mainThread.asyncMutating(execute: work)
    }
    
    @discardableResult
    public func asyncMutating<S>(state: S, execute work: @MainActor @escaping (S, inout Value) -> Void) -> DispatchWorkItem {
        return self.mainThread.asyncMutating(state: state, execute: work)
    }
    
    @discardableResult
    public func asyncMutating(deadline: DispatchTime, execute work: @MainActor @escaping (inout Value) -> Void) -> DispatchWorkItem {
        return self.mainThread.asyncMutating(deadline: deadline, execute: work)
    }
    
    @discardableResult
    public func asyncMutating<S>(state: S, deadline: DispatchTime, execute work: @MainActor @escaping (S, inout Value) -> Void) -> DispatchWorkItem {
        return self.mainThread.asyncMutating(state: state, deadline: deadline, execute: work)
    }
    
}
