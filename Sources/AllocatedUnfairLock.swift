//
//  AllocatedUnfairLock.swift
//  ThreadSafe
//
//  Created by jiasong on 2024/5/22.
//

import Foundation

public final class AllocatedUnfairLock<State> {
    
    private var state: State
    private let lock: os_unfair_lock_t
    
    public init(state: State) {
        self.state = state
        self.lock = .allocate(capacity: 1)
        self.lock.initialize(to: os_unfair_lock())
    }
    
    deinit {
        self.lock.deinitialize(count: 1)
        self.lock.deallocate()
    }
    
}

extension AllocatedUnfairLock {
    
    public func withLock<T>(_ body: (inout State) throws -> T) rethrows -> T {
        os_unfair_lock_lock(self.lock)
        defer {
            os_unfair_lock_unlock(self.lock)
        }
        return try body(&self.state)
    }
    
}

extension AllocatedUnfairLock where State == Void {
    
    public convenience init() {
        self.init(state: ())
    }
    
    public func withLock<T>(_ body: () throws -> T) rethrows -> T {
        return try self.withLock { _ in
            return try body()
        }
    }
}
