//
//  ThreadSafeCompatible.swift
//  ThreadSafe
//
//  Created by jiasong on 2024/5/30.
//

import Foundation

public struct ThreadSafeWrapper<Base> {
    
    public let base: Base
    
    public init(_ base: Base) {
        self.base = base
    }
    
}

public protocol ThreadSafeCompatible {}

extension ThreadSafeCompatible {
    
    public static var threadSafe: ThreadSafeWrapper<Self>.Type {
        get { ThreadSafeWrapper<Self>.self }
        set { }
    }
    
    public var threadSafe: ThreadSafeWrapper<Self> {
        get { ThreadSafeWrapper(self) }
        set { }
    }
    
}

public protocol ThreadSafeCompatibleObject: AnyObject {}

extension ThreadSafeCompatibleObject {
    
    public static var threadSafe: ThreadSafeWrapper<Self>.Type {
        get { ThreadSafeWrapper<Self>.self }
        set { }
    }
    
    public var threadSafe: ThreadSafeWrapper<Self> {
        get { ThreadSafeWrapper(self) }
        set { }
    }
    
}

extension NSObject: ThreadSafeCompatibleObject {}
