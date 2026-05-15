//
//  ReadWriteTask.swift
//  ThreadSafe
//
//  Created by jiasong on 2024/5/30.
//

import Foundation

public final class ReadWriteTask {
    
    public enum Attributes: Equatable {
        case serial
        case concurrent
    }
    
    public enum QoS: Equatable {
        case background
        case utility
        case `default`
        case userInitiated
        case userInteractive
        case unspecified
    }
    
    public enum AutoreleaseFrequency: Equatable {
        case inherit
        case workItem
        case never
    }
    
    public final class AsyncToken {
        
        public var isCancelled: Bool {
            return self.workItem.isCancelled
        }
        
        public func cancel() {
            self.workItem.cancel()
        }
        
        private let workItem: DispatchWorkItem
        
        fileprivate init(workItem: DispatchWorkItem) {
            self.workItem = workItem
        }
        
    }
    
    public let label: String
    
    public let qos: QoS
    public let attributes: Attributes
    public let autoreleaseFrequency: AutoreleaseFrequency
    
    private static let specificKey = DispatchSpecificKey<Set<AtomicInt>>()
    
    private let adapter: ReadWriteTaskAdapter
    
    private let initiallyContext = AtomicInt()
    private let contextLock = UnfairLock()
    
    public init(
        label: String,
        qos: QoS = .unspecified,
        attributes: Attributes = .concurrent,
        autoreleaseFrequency: AutoreleaseFrequency = .inherit
    ) {
        self.label = label
        self.qos = qos
        self.attributes = attributes
        self.autoreleaseFrequency = autoreleaseFrequency
        
        switch self.attributes {
        case .serial:
            self.adapter = SerialTaskAdapter(label: label, qos: qos, autoreleaseFrequency: autoreleaseFrequency)
        case .concurrent:
            self.adapter = ConcurrentTaskAdapter(label: label, qos: qos, autoreleaseFrequency: autoreleaseFrequency)
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
    
    @discardableResult
    public func asyncWrite(execute work: @escaping () -> Void) -> AsyncToken {
        return self.adapter.asyncWrite(execute: work)
    }
    
    @discardableResult
    public func asyncWrite<S>(state: S, execute work: @escaping (S) -> Void) -> AsyncToken {
        return self.asyncWrite {
            work(state)
        }
    }
    
    @discardableResult
    public func asyncWriteAfter(deadline: DispatchTime, execute work: @escaping () -> Void) -> AsyncToken {
        return self.adapter.asyncWriteAfter(deadline: deadline, execute: work)
    }
    
    @discardableResult
    public func asyncWriteAfter<S>(state: S, deadline: DispatchTime, execute work: @escaping (S) -> Void) -> AsyncToken {
        return self.asyncWriteAfter(deadline: deadline) {
            work(state)
        }
    }
    
}

extension ReadWriteTask {
    
    private func getCurrentContext() -> Set<AtomicInt> {
        return DispatchQueue.getSpecific(key: Self.specificKey) ?? []
    }
    
    private func isInQueue(with currentContext: Set<AtomicInt>) -> Bool {
        return self.contextLock.withLock {
            let context = self.adapter.queue.getSpecific(key: Self.specificKey) ?? []
            assert(context.count > 0)
            return currentContext.contains(where: { context.contains($0) })
        }
    }
    
    private func setContext(with currentContext: Set<AtomicInt>) {
        self.contextLock.withLock {
            let previous = self.adapter.queue.getSpecific(key: Self.specificKey) ?? []
            var context = previous
            currentContext.forEach {
                context.insert($0)
            }
            assert(context.count > 0)
            guard context.count != previous.count else {
                return
            }
            self.adapter.queue.setSpecific(key: Self.specificKey, value: context)
        }
    }
    
    private func removeContext(with currentContext: Set<AtomicInt>) {
        self.contextLock.withLock {
            let previous = self.adapter.queue.getSpecific(key: Self.specificKey) ?? []
            var context = previous
            previous.forEach {
                guard $0 != self.initiallyContext && currentContext.contains($0) else {
                    return
                }
                context.remove($0)
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
    func asyncWrite(execute work: @escaping () -> Void) -> ReadWriteTask.AsyncToken
    func asyncWriteAfter(deadline: DispatchTime, execute work: @escaping () -> Void) -> ReadWriteTask.AsyncToken
}

private final class SerialTaskAdapter: ReadWriteTaskAdapter {
    
    let queue: DispatchQueue
    
    init(
        label: String,
        qos: ReadWriteTask.QoS,
        autoreleaseFrequency: ReadWriteTask.AutoreleaseFrequency
    ) {
        self.queue = DispatchQueue(
            label: label,
            qos: .init(qos),
            autoreleaseFrequency: .init(autoreleaseFrequency)
        )
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
    
    func asyncWrite(execute work: @escaping () -> Void) -> ReadWriteTask.AsyncToken {
        let workItem = DispatchWorkItem(block: work)
        self.queue.async(execute: workItem)
        return .init(workItem: workItem)
    }
    
    func asyncWriteAfter(deadline: DispatchTime, execute work: @escaping () -> Void) -> ReadWriteTask.AsyncToken {
        let workItem = DispatchWorkItem(block: work)
        self.queue.asyncAfter(deadline: deadline, execute: workItem)
        return .init(workItem: workItem)
    }
    
}

private final class ConcurrentTaskAdapter: ReadWriteTaskAdapter {
    
    let queue: DispatchQueue
    
    private let asyncWriteQueue: DispatchQueue
    
    @UnfairLockValueWrapper
    private var readingCount: UInt = 0
    
    @UnfairLockValueWrapper
    private var writingCount: UInt = 0
    
    init(
        label: String,
        qos: ReadWriteTask.QoS,
        autoreleaseFrequency: ReadWriteTask.AutoreleaseFrequency
    ) {
        self.queue = DispatchQueue(
            label: label,
            qos: .init(qos),
            attributes: .concurrent,
            autoreleaseFrequency: .init(autoreleaseFrequency)
        )
        self.asyncWriteQueue = DispatchQueue(
            label: "\(self.queue.label).async-write",
            qos: .init(qos),
            autoreleaseFrequency: .init(autoreleaseFrequency)
        )
    }
    
    func read<T>(inQueue isInQueue: Bool, execute work: () throws -> T) rethrows -> T {
        if self.readingCount > 0 && isInQueue {
            assertionFailure("在「read」中嵌套「read」会造成死锁且无法规避，请避免使用")
            return try work()
        } else if self.writingCount > 0 && isInQueue {
            /// 在「write」中嵌套「read」会造成死锁，这里规避掉了死锁
            return try work()
        } else {
            return try self.queue.sync {
                self.$readingCount.mutating { $0 += 1 }
                defer {
                    self.$readingCount.mutating { $0 -= 1 }
                }
                return try work()
            }
        }
    }
    
    func write<T>(inQueue isInQueue: Bool, execute work: () throws -> T) rethrows -> T {
        if self.readingCount > 0 && isInQueue {
            assertionFailure("在「read」中嵌套「write」会造成死锁且无法规避，请避免使用")
            return try work()
        } else if self.writingCount > 0 && isInQueue {
            /// 在「write」中嵌套「write」会造成死锁，这里规避掉了死锁
            return try work()
        } else {
            return try self.queue.sync(flags: .barrier) {
                self.$writingCount.mutating { $0 += 1 }
                defer {
                    self.$writingCount.mutating { $0 -= 1 }
                }
                return try work()
            }
        }
    }
    
    func asyncWrite(execute work: @escaping () -> Void) -> ReadWriteTask.AsyncToken {
        // https://stackoverflow.com/questions/76457430/why-is-this-swift-readers-writers-code-causing-deadlock
        // 若开启的「sync」过多，又正在执行「async(flags: .barrier)」，当线程池耗尽时会导致死锁
        // 这里使用另一个串行队列，通过异步调用、同步write的方式来解决这个问题，同时串行队列会保证调用顺序
        let workItem = DispatchWorkItem {
            self.write(inQueue: false) {
                work()
            }
        }
        self.asyncWriteQueue.async(execute: workItem)
        return .init(workItem: workItem)
    }
    
    func asyncWriteAfter(deadline: DispatchTime, execute work: @escaping () -> Void) -> ReadWriteTask.AsyncToken {
        let workItem = DispatchWorkItem {
            self.write(inQueue: false) {
                work()
            }
        }
        self.asyncWriteQueue.asyncAfter(deadline: deadline, execute: workItem)
        return .init(workItem: workItem)
    }
    
}

private struct AtomicInt: Hashable {
    
    private static let lock = UnfairLock()
    private static var current: UInt = 1
    
    private let value: UInt
    
    fileprivate init() {
        self.value = AtomicInt.lock.withLock {
            let value = AtomicInt.current
            AtomicInt.current = value + 1
            return value
        }
    }
}

private extension DispatchQoS {
    
    init(_ qos: ReadWriteTask.QoS) {
        switch qos {
        case .background:
            self = .background
        case .utility:
            self = .utility
        case .default:
            self = .default
        case .userInitiated:
            self = .userInitiated
        case .userInteractive:
            self = .userInteractive
        case .unspecified:
            self = .unspecified
        }
    }
    
}

private extension DispatchQueue.AutoreleaseFrequency {
    
    init(_ autoreleaseFrequency: ReadWriteTask.AutoreleaseFrequency) {
        switch autoreleaseFrequency {
        case .inherit:
            self = .inherit
        case .workItem:
            self = .workItem
        case .never:
            self = .never
        }
    }
    
}
