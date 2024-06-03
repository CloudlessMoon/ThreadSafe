//
//  DispatchQueue+Extension.swift
//  ThreadSafe
//
//  Created by jiasong on 2024/5/30.
//

import Foundation

fileprivate extension DispatchQueue {
    
    static let mainKey: DispatchSpecificKey<UUID> = {
        let key = DispatchSpecificKey<UUID>()
        DispatchQueue.main.setSpecific(key: key, value: UUID())
        return key
    }()
    
}

public extension ThreadSafeWrapper where Base: DispatchQueue {
    
    static var isMain: Bool {
        return Base.getSpecific(key: Base.mainKey) != nil
    }
    
    static func onMain(execute work: @escaping () -> Void) {
        if Base.threadSafe.isMain {
            work()
        } else {
            Base.main.async {
                work()
            }
        }
    }
    
    static func assertOnMainQueue() {
        assert(DispatchQueue.threadSafe.isMain, "not in the main queue")
    }
    
    static func assertNotOnMainQueue() {
        assert(!DispatchQueue.threadSafe.isMain, "in the main queue")
    }
    
}
