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
    
    private static let specificKey = DispatchSpecificKey<[UUID]>()
    
    private let adapter: ReadWriteAdapter
    
    private let contextValue = UUID()
    private let contextQueue = DispatchQueue(label: "com.jiasong.thread-safe.context")
    
    public init(label: String, attributes: Attributes = .concurrent) {
        self.attributes = attributes
        
        switch self.attributes {
        case .serial:
            self.adapter = ReadWriteSerialAdapter(label: label)
        case .concurrent:
            self.adapter = ReadWriteConcurrentAdapter(label: label)
        }
        
        self.adapter.queue.setSpecific(key: ReadWriteTask.specificKey, value: [self.contextValue])
    }
    
    deinit {
        self.adapter.queue.setSpecific(key: ReadWriteTask.specificKey, value: nil)
    }
    
}

extension ReadWriteTask {
    
    public func read<T>(execute work: () throws -> T) rethrows -> T {
        let current = self.currentContext
        return try self.adapter.read(in: self.isCurrentQueue(with: current)) {
            self.setContext(with: current)
            defer {
                self.removeContext(with: current)
            }
            return try work()
        }
    }
    
    public func read<S, T>(state: S, execute work: (S) throws -> T) rethrows -> T {
        return try self.read {
            return try work(state)
        }
    }
    
    @discardableResult
    public func write<T>(execute work: () throws -> T) rethrows -> T {
        let current = self.currentContext
        return try self.adapter.write(in: self.isCurrentQueue(with: current)) {
            self.setContext(with: current)
            defer {
                self.removeContext(with: current)
            }
            return try work()
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
    
    private var currentContext: [UUID] {
        return DispatchQueue.getSpecific(key: ReadWriteTask.specificKey) ?? []
    }
    
    private func isCurrentQueue(with current: [UUID]) -> Bool {
        return self.contextQueue.sync {
            let target = self.adapter.queue.getSpecific(key: ReadWriteTask.specificKey) ?? []
            return current.contains(where: { target.firstIndex(of: $0) != nil })
        }
    }
    
    private func setContext(with current: [UUID]) {
        self.contextQueue.sync {
            var target = self.adapter.queue.getSpecific(key: ReadWriteTask.specificKey) ?? []
            current.forEach {
                guard target.firstIndex(of: $0) == nil else {
                    return
                }
                target.append($0)
            }
            self.adapter.queue.setSpecific(key: ReadWriteTask.specificKey, value: target)
        }
    }
    
    private func removeContext(with current: [UUID]) {
        self.contextQueue.sync {
            var target = self.adapter.queue.getSpecific(key: ReadWriteTask.specificKey) ?? []
            target.removeAll {
                return current.firstIndex(of: $0) != nil && $0 != self.contextValue
            }
            self.adapter.queue.setSpecific(key: ReadWriteTask.specificKey, value: target)
        }
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
        self.asyncWriteQueue = DispatchQueue(label: "\(label).async-write")
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
        // 这里使用另一个串行队列，通过异步调用、同步write的方式来解决这个问题，同时串行队列会保证调用顺序
        self.asyncWriteQueue.async {
            self.write(in: false) {
                work()
            }
        }
    }
    
}
