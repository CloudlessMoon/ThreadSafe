//
//  MainThreadTask.swift
//  ThreadSafe
//
//  Created by jiasong on 2024/12/11.
//

import Foundation

public final class MainThreadTask {
    
    public static let `default` = MainThreadTask(label: "Default")
    
    public let label: String
    
    public init(label: String) {
        self.label = label
    }
    
}

extension MainThreadTask {
    
    @discardableResult
    public func sync<T>(execute work: @MainActor () throws -> T) rethrows -> T {
        if Thread.isMainThread || DispatchQueue.threadSafe.isMain {
            return try MainActor.assumeIsolated(work)
        } else {
            DispatchQueue.threadSafe.assertNotOnMainQueue()
            return try DispatchQueue.main.sync {
                return try work()
            }
        }
    }
    
    public func sync<S, T>(state: S, execute work: @MainActor (S) throws -> T) rethrows -> T {
        return try self.sync {
            return try work(state)
        }
    }
    
    public func currentOrAsync(execute work: @MainActor @escaping () -> Void) {
        if Thread.isMainThread || DispatchQueue.threadSafe.isMain {
            self.sync(execute: work)
        } else {
            self.async(execute: work)
        }
    }
    
    public func currentOrAsync<S>(state: S, execute work: @MainActor @escaping (S) -> Void) {
        if Thread.isMainThread || DispatchQueue.threadSafe.isMain {
            self.sync(state: state, execute: work)
        } else {
            self.async(state: state, execute: work)
        }
    }
    
    @discardableResult
    public func async(execute work: @MainActor @escaping () -> Void) -> DispatchWorkItem {
        let workItem = DispatchWorkItem(block: work)
        DispatchQueue.main.async(execute: workItem)
        return workItem
    }
    
    @discardableResult
    public func async<S>(state: S, execute work: @MainActor @escaping (S) -> Void) -> DispatchWorkItem {
        return self.async {
            work(state)
        }
    }
    
    @discardableResult
    public func asyncAfter(deadline: DispatchTime, execute work: @MainActor @escaping () -> Void) -> DispatchWorkItem {
        let workItem = DispatchWorkItem(block: work)
        DispatchQueue.main.asyncAfter(deadline: deadline, execute: workItem)
        return workItem
    }
    
    @discardableResult
    public func asyncAfter<S>(state: S, deadline: DispatchTime, execute work: @MainActor @escaping (S) -> Void) -> DispatchWorkItem {
        return self.asyncAfter(deadline: deadline) {
            work(state)
        }
    }
    
}

extension MainThreadTask {
    
    public static func assertOnMainThread() {
        assert(Thread.isMainThread, "not in the main thread")
    }
    
    public static func assertNotOMainThread() {
        assert(!Thread.isMainThread, "in the main thread")
    }
    
}
