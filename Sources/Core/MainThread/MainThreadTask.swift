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
    public func sync<T>(execute work: () throws -> T) rethrows -> T {
        if Thread.isMainThread || DispatchQueue.threadSafe.isMain {
            return try work()
        } else {
            DispatchQueue.threadSafe.assertNotOnMainQueue()
            return try DispatchQueue.main.sync {
                return try work()
            }
        }
    }
    
    public func sync<S, T>(state: S, execute work: (S) throws -> T) rethrows -> T {
        return try self.sync {
            return try work(state)
        }
    }
    
    public func currentOrAsync(execute work: @escaping () -> Void) {
        if Thread.isMainThread {
            self.sync(execute: work)
        } else {
            self.async(execute: work)
        }
    }
    
    public func async(execute work: @escaping () -> Void) {
        DispatchQueue.main.async {
            work()
        }
    }
    
    public func async<S>(state: S, execute work: @escaping (S) -> Void) {
        self.async {
            work(state)
        }
    }
    
}
