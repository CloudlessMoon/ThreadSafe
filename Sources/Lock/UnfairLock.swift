//
//  UnfairLock.swift
//  ThreadSafe
//
//  Created by jiasong on 2024/5/22.
//

import Foundation
import os.lock

public final class UnfairLock {
    
    private let lock: os_unfair_lock_t
    
    public init() {
        self.lock = .allocate(capacity: 1)
        self.lock.initialize(to: os_unfair_lock())
    }
    
    deinit {
        self.lock.deinitialize(count: 1)
        self.lock.deallocate()
    }
    
}

extension UnfairLock {
    
    public func withLock<T>(execute work: () throws -> T) rethrows -> T {
        os_unfair_lock_lock(self.lock)
        defer {
            os_unfair_lock_unlock(self.lock)
        }
        return try work()
    }
    
}
