//
//  ReadWriteTask.swift
//  ThreadSafe
//
//  Created by jiasong on 2024/5/28.
//

import Foundation

public final class ReadWriteTask {
    
    private static let specificKey = DispatchSpecificKey<UUID>()
    
    private let dataQueue: DispatchQueue
    
    private let isReadingLock: AllocatedUnfairLock<Bool>
    private let isWritingLock: AllocatedUnfairLock<Bool>
    
    public init(label: String) {
        self.dataQueue = DispatchQueue(label: label, attributes: .concurrent)
        self.dataQueue.setSpecific(key: ReadWriteTask.specificKey, value: UUID())
        
        self.isReadingLock = AllocatedUnfairLock(state: false)
        self.isWritingLock = AllocatedUnfairLock(state: false)
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
            return try self.dataQueue.sync {
                self.isReading = true
                defer {
                    self.isReading = false
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
            return try self.dataQueue.sync(flags: .barrier) {
                self.isWriting = true
                defer {
                    self.isWriting = false
                }
                return try work()
            }
        }
    }
    
    public func asyncWrite(execute work: @escaping () -> Void) {
        self.dataQueue.async(flags: .barrier) {
            self.isWriting = true
            defer {
                self.isWriting = false
            }
            work()
        }
    }
    
}

extension ReadWriteTask {
    
    private var isCurrentQueue: Bool {
        let lhs = self.dataQueue.getSpecific(key: ReadWriteTask.specificKey)
        let rhs = DispatchQueue.getSpecific(key: ReadWriteTask.specificKey)
        return lhs == rhs
    }
    
    private var isReading: Bool {
        get {
            return self.isReadingLock.withLock { $0 }
        }
        set {
            self.isReadingLock.withLock { $0 = newValue }
        }
    }
    
    private var isWriting: Bool {
        get {
            return self.isWritingLock.withLock { $0 }
        }
        set {
            self.isWritingLock.withLock { $0 = newValue }
        }
    }
    
}
