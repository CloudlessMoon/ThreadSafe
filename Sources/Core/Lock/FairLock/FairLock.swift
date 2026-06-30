//
//  FairLock.swift
//  ThreadSafe
//
//  Created by jiasong on 2026/6/29.
//

import Foundation

public final class FairLock {
    
    private let lock: NSLock
    
    public init() {
        self.lock = NSLock()
    }
    
}

extension FairLock {
    
    public func withLock<T>(execute work: () throws -> T) rethrows -> T {
        return try self.lock.withLock(work)
    }
    
    public func withLock<S, T>(state: S, execute work: (S) throws -> T) rethrows -> T {
        return try self.withLock {
            return try work(state)
        }
    }
    
}
