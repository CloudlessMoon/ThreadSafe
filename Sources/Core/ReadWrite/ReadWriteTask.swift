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
    
    public let label: String
    
    public let attributes: Attributes
    
    private static let specificKey = DispatchSpecificKey<[AtomicInt]>()
    
    private let adapter: ReadWriteTaskAdapter
    
    private let initiallyContext = AtomicInt()
    private let contextLock = UnfairLock()
    
    public init(label: String, attributes: Attributes = .concurrent) {
        self.label = label
        self.attributes = attributes
        
        switch self.attributes {
        case .serial:
            self.adapter = SerialTaskAdapter(label: label)
        case .concurrent:
            self.adapter = ConcurrentTaskAdapter(label: label)
        }
        
        self.adapter.queue.setSpecific(key: Self.specificKey, value: [self.initiallyContext])
    }
    
}

extension ReadWriteTask {
    
    public func read<T>(execute work: () throws -> T) rethrows -> T {
        let currentContext = self.getCurrentContext()
        let isInQueue = self.isInQueue(with: currentContext)
        return try self.adapter.read(inQueue: isInQueue) {
            if isInQueue {
                return try work()
            } else {
                self.setContext(with: currentContext)
                defer {
                    self.removeContext(with: currentContext)
                }
                return try work()
            }
        }
    }
    
    public func read<S, T>(state: S, execute work: (S) throws -> T) rethrows -> T {
        return try self.read {
            return try work(state)
        }
    }
    
    @discardableResult
    public func write<T>(execute work: () throws -> T) rethrows -> T {
        let currentContext = self.getCurrentContext()
        let isInQueue = self.isInQueue(with: currentContext)
        return try self.adapter.write(inQueue: isInQueue) {
            if isInQueue {
                return try work()
            } else {
                self.setContext(with: currentContext)
                defer {
                    self.removeContext(with: currentContext)
                }
                return try work()
            }
        }
    }
    
    @discardableResult
    public func write<S, T>(state: S, execute work: (S) throws -> T) rethrows -> T {
        return try self.write {
            return try work(state)
        }
    }
    
    public func asyncWrite(execute work: @escaping () -> Void) {
        self.adapter.asyncWrite(execute: work)
    }
    
    public func asyncWrite<S>(state: S, execute work: @escaping (S) -> Void) {
        self.asyncWrite {
            work(state)
        }
    }
    
}

extension ReadWriteTask {
    
    private func getCurrentContext() -> [AtomicInt] {
        return DispatchQueue.getSpecific(key: Self.specificKey) ?? []
    }
    
    private func isInQueue(with currentContext: [AtomicInt]) -> Bool {
        return self.contextLock.withLock {
            let context = self.adapter.queue.getSpecific(key: Self.specificKey) ?? []
            assert(context.count > 0)
            return currentContext.contains(where: { context.firstIndex(of: $0) != nil })
        }
    }
    
    private func setContext(with currentContext: [AtomicInt]) {
        self.contextLock.withLock {
            let previous = self.adapter.queue.getSpecific(key: Self.specificKey) ?? []
            var context = previous
            currentContext.forEach {
                guard context.firstIndex(of: $0) == nil else {
                    return
                }
                context.append($0)
            }
            assert(context.count > 0)
            guard context.count != previous.count else {
                return
            }
            self.adapter.queue.setSpecific(key: Self.specificKey, value: context)
        }
    }
    
    private func removeContext(with currentContext: [AtomicInt]) {
        self.contextLock.withLock {
            let previous = self.adapter.queue.getSpecific(key: Self.specificKey) ?? []
            var context = previous
            context.removeAll {
                return $0 != self.initiallyContext && currentContext.firstIndex(of: $0) != nil
            }
            assert(context.count > 0)
            guard context.count != previous.count else {
                return
            }
            self.adapter.queue.setSpecific(key: Self.specificKey, value: context)
        }
    }
    
}

private protocol ReadWriteTaskAdapter {
    
    var queue: DispatchQueue { get }
    
    func read<T>(inQueue isInQueue: Bool, execute work: () throws -> T) rethrows -> T
    func write<T>(inQueue isInQueue: Bool, execute work: () throws -> T) rethrows -> T
    func asyncWrite(execute work: @escaping () -> Void)
    
}

private final class SerialTaskAdapter: ReadWriteTaskAdapter {
    
    let queue: DispatchQueue
    
    init(label: String) {
        self.queue = DispatchQueue(label: label)
    }
    
    func read<T>(inQueue isInQueue: Bool, execute work: () throws -> T) rethrows -> T {
        if isInQueue {
            return try work()
        } else {
            return try self.queue.sync(execute: work)
        }
    }
    
    func write<T>(inQueue isInQueue: Bool, execute work: () throws -> T) rethrows -> T {
        if isInQueue {
            return try work()
        } else {
            return try self.queue.sync(execute: work)
        }
    }
    
    func asyncWrite(execute work: @escaping () -> Void) {
        self.queue.async(execute: work)
    }
    
}

private final class ConcurrentTaskAdapter: ReadWriteTaskAdapter {
    
    let queue: DispatchQueue
    
    private let asyncWriteQueue: DispatchQueue
    
    @UnfairLockValueWrapper
    private var isReading: Bool = false
    
    @UnfairLockValueWrapper
    private var isWriting: Bool = false
    
    init(label: String) {
        self.queue = DispatchQueue(label: label, attributes: .concurrent)
        self.asyncWriteQueue = DispatchQueue(label: "\(self.queue.label).async-write")
    }
    
    func read<T>(inQueue isInQueue: Bool, execute work: () throws -> T) rethrows -> T {
        if self.isReading && isInQueue {
            assertionFailure("在「read」中嵌套「read」会造成死锁且无法规避，请避免使用")
            return try work()
        } else if self.isWriting && isInQueue {
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
    
    func write<T>(inQueue isInQueue: Bool, execute work: () throws -> T) rethrows -> T {
        if self.isReading && isInQueue {
            assertionFailure("在「read」中嵌套「write」会造成死锁且无法规避，请避免使用")
            return try work()
        } else if self.isWriting && isInQueue {
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
        // 这里使用另一个串行队列，通过异步调用、同步write的方式来解决这个问题，同时串行队列会保证调用顺序
        self.asyncWriteQueue.async {
            self.write(inQueue: false) {
                work()
            }
        }
    }
    
}

private struct AtomicInt: Equatable {
    
    private static let lock = UnfairLock()
    private static var current: Int = 1
    
    private let value: Int
    
    fileprivate init() {
        self.value = AtomicInt.lock.withLock {
            let value = AtomicInt.current
            AtomicInt.current = value + 1
            return value
        }
    }
}
