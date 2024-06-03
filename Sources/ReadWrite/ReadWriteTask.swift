//
//  ReadWriteTask.swift
//  ThreadSafe
//
//  Created by jiasong on 2024/5/30.
//

import Foundation

public final class ReadWriteTask {
    
    public enum Attributes {
        case serial
        case concurrent
    }
    
    public let attributes: Attributes
    
    private static let specificKey = DispatchSpecificKey<UUID>()
    
    private let adapter: ReadWriteAdapter
    
    public init(label: String, attributes: Attributes = .concurrent) {
        self.attributes = attributes
        
        switch self.attributes {
        case .serial:
            self.adapter = ReadWriteSerialAdapter(label: label)
        case .concurrent:
            self.adapter = ReadWriteConcurrentAdapter(label: label)
        }
        
        self.adapter.queue.setSpecific(key: ReadWriteTask.specificKey, value: UUID())
    }
    
    deinit {
        self.adapter.queue.setSpecific(key: ReadWriteTask.specificKey, value: nil)
    }
    
    private var isCurrentQueue: Bool {
        let lhs = self.adapter.queue.getSpecific(key: ReadWriteTask.specificKey)
        let rhs = DispatchQueue.getSpecific(key: ReadWriteTask.specificKey)
        return lhs == rhs
    }
    
}

extension ReadWriteTask {
    
    public func read<T>(execute work: () throws -> T) rethrows -> T {
        return try self.adapter.read(in: self.isCurrentQueue, execute: work)
    }
    
    @discardableResult
    public func write<T>(execute work: () throws -> T) rethrows -> T {
        return try self.adapter.write(in: self.isCurrentQueue, execute: work)
    }
    
    public func asyncWrite(execute work: @escaping () -> Void) {
        self.adapter.asyncWrite(execute: work)
    }
    
}

private protocol ReadWriteAdapter {
    
    var queue: DispatchQueue { get }
    
    init(label: String)
    
    func read<T>(in currentQueue: Bool, execute work: () throws -> T) rethrows -> T
    func write<T>(in currentQueue: Bool, execute work: () throws -> T) rethrows -> T
    func asyncWrite(execute work: @escaping () -> Void)
    
}

private final class ReadWriteSerialAdapter: ReadWriteAdapter {
    
    let queue: DispatchQueue
    
    init(label: String) {
        self.queue = DispatchQueue(label: label)
    }
    
    func read<T>(in currentQueue: Bool, execute work: () throws -> T) rethrows -> T {
        if currentQueue {
            return try work()
        } else {
            return try self.queue.sync(execute: work)
        }
    }
    
    func write<T>(in currentQueue: Bool, execute work: () throws -> T) rethrows -> T {
        if currentQueue {
            return try work()
        } else {
            return try self.queue.sync(execute: work)
        }
    }
    
    func asyncWrite(execute work: @escaping () -> Void) {
        self.queue.async(execute: work)
    }
    
}

private final class ReadWriteConcurrentAdapter: ReadWriteAdapter {
    
    let queue: DispatchQueue
    
    private let asyncWriteQueue: DispatchQueue
    
    @UnfairLockValueWrapper
    private var isReading: Bool = false
    
    @UnfairLockValueWrapper
    private var isWriting: Bool = false
    
    init(label: String) {
        self.queue = DispatchQueue(label: label, attributes: .concurrent)
        self.asyncWriteQueue = DispatchQueue(label: "\(label).async-write", attributes: .concurrent)
    }
    
    func read<T>(in currentQueue: Bool, execute work: () throws -> T) rethrows -> T {
        if self.isReading && currentQueue {
            assertionFailure("在「read」中嵌套「read」会造成死锁且无法规避，请避免使用")
            return try work()
        } else if self.isWriting && currentQueue {
            /// 在「write」中嵌套「read」会造成死锁，这里规避掉了死锁
            return try work()
        } else {
            return try self.queue.sync {
                self.isReading = true
                defer {
                    self.isReading = false
                }
                return try work()
            }
        }
    }
    
    func write<T>(in currentQueue: Bool, execute work: () throws -> T) rethrows -> T {
        if self.isReading && currentQueue {
            assertionFailure("在「read」中嵌套「write」会造成死锁且无法规避，请避免使用")
            return try work()
        } else if self.isWriting && currentQueue {
            /// 在「write」中嵌套「write」会造成死锁，这里规避掉了死锁
            return try work()
        } else {
            return try self.queue.sync(flags: .barrier) {
                self.isWriting = true
                defer {
                    self.isWriting = false
                }
                return try work()
            }
        }
    }
    
    func asyncWrite(execute work: @escaping () -> Void) {
        // https://stackoverflow.com/questions/76457430/why-is-this-swift-readers-writers-code-causing-deadlock
        // 若开启的「sync」过多，又正在执行「async(flags: .barrier)」，当线程池耗尽时会导致死锁
        // 这里使用另一个并行队列，通过异步调用、同步write的方式来解决这个问题
        self.asyncWriteQueue.async {
            self.write(in: false) {
                work()
            }
        }
    }
    
}
