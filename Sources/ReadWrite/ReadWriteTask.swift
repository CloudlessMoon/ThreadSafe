//
//  ReadWriteTask.swift
//  ThreadSafe
//
//  Created by jiasong on 2024/5/30.
//

import Foundation

public final class ReadWriteTask {
    
    private static let specificKey = DispatchSpecificKey<UUID>()
    
    private let dataQueue: DispatchQueue
    
    @UnfairLockValueWrapper
    private var isReading: Bool = false
    
    @UnfairLockValueWrapper
    private var isWriting: Bool = false
    
    @UnfairLockValueWrapper
    private var isAsyncWriting: Bool = false
    
    @UnfairLockValueWrapper
    private var syncCount: Int = 0
    
    private var isCurrentQueue: Bool {
        let lhs = self.dataQueue.getSpecific(key: ReadWriteTask.specificKey)
        let rhs = DispatchQueue.getSpecific(key: ReadWriteTask.specificKey)
        return lhs == rhs
    }
    
    public init(label: String) {
        self.dataQueue = DispatchQueue(label: label, attributes: .concurrent)
        self.dataQueue.setSpecific(key: ReadWriteTask.specificKey, value: UUID())
    }
    
    deinit {
        self.dataQueue.setSpecific(key: ReadWriteTask.specificKey, value: nil)
    }
    
}

extension ReadWriteTask {
    
    public func read<T>(execute work: () throws -> T) rethrows -> T {
        let isCurrentQueue = self.isCurrentQueue
        if self.isReading && isCurrentQueue {
            assertionFailure("在「read」中嵌套「read」会造成死锁且无法规避，请避免使用")
            return try work()
        } else if self.isWriting && isCurrentQueue {
            /// 在「write」中嵌套「read」会造成死锁，这里规避掉了死锁
            return try work()
        } else {
            self.assertSyncPrecondition()
            
            self.syncCount += 1
            return try self.dataQueue.sync {
                self.isReading = true
                defer {
                    self.isReading = false
                    self.syncCount -= 1
                }
                return try work()
            }
        }
    }
    
    @discardableResult
    public func write<T>(execute work: () throws -> T) rethrows -> T {
        let isCurrentQueue = self.isCurrentQueue
        if self.isReading && isCurrentQueue {
            assertionFailure("在「read」中嵌套「write」会造成死锁且无法规避，请避免使用")
            return try work()
        } else if self.isWriting && isCurrentQueue {
            /// 在「write」中嵌套「write」会造成死锁，这里规避掉了死锁
            return try work()
        } else {
            self.assertSyncPrecondition()
            
            self.syncCount += 1
            return try self.dataQueue.sync(flags: .barrier) {
                self.isWriting = true
                defer {
                    self.isWriting = false
                    self.syncCount -= 1
                }
                return try work()
            }
        }
    }
    
    public func asyncWrite(execute work: @escaping () -> Void) {
        self.isAsyncWriting = true
        self.dataQueue.async(flags: .barrier) {
            self.isWriting = true
            defer {
                self.isWriting = false
                self.isAsyncWriting = false
            }
            work()
        }
    }
    
}

extension ReadWriteTask {
    
    private func assertSyncPrecondition() {
        // https://stackoverflow.com/questions/76457430/why-is-this-swift-readers-writers-code-causing-deadlock
        assert(self.syncCount <= 50 || !self.isAsyncWriting, "警告：开启的「sync」过多，又正在执行「asyncWrite」，当线程池耗尽时会导致死锁，请使用「write」")
    }
    
}
