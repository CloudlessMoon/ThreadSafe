//
//  ViewController.swift
//  ThreadSafeExample
//
//  Created by jiasong on 2024/5/30.
//

import UIKit
import ThreadSafe

class ViewController: UIViewController {
    
    @UnfairLockValueWrapper
    var readWriteCount: Int = 0 {
        didSet {
            print("readWriteCount \(self.readWriteCount)")
        }
    }
    
    let concurrentQueue = DispatchQueue(label: "concurrent", attributes: .concurrent)
    
    let readWriteTask = ReadWriteTask(label: "test", attributes: .concurrent)
    
    var name = "0"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let count = 1000
        for item in 1...count {
            self.concurrentQueue.async {
                _ = self.readWriteTask.read { defer { self.readWriteCount += 1 }; return self.name }
                
                self.readWriteTask.write {
                    self.readWriteCount += 1
                    
                    self.name = "\(item)"
                    
                    _ = self.readWriteTask.read { defer { self.readWriteCount += 1 }; return self.name }
                    
                    self.readWriteTask.write {
                        self.readWriteCount += 1
                        
                        self.name = "\(item)"
                    }
                    
                    self.readWriteTask.asyncWrite {
                        self.readWriteCount += 1
                        
                        self.name = "\(item)"
                        
                        _ = self.readWriteTask.read { defer { self.readWriteCount += 1 }; return self.name }
                    }
                }
            }
            
            self.concurrentQueue.async {
                self.readWriteTask.asyncWrite {
                    self.readWriteCount += 1
                    
                    _ = self.readWriteTask.read { defer { self.readWriteCount += 1 }; return self.name }
                    
                    self.name = "\(item)"
                    
                    self.readWriteTask.write {
                        self.readWriteCount += 1
                        
                        self.name = "\(item)"
                        
                        _ = self.readWriteTask.read { defer { self.readWriteCount += 1 }; return self.name }
                    }
                }
                
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            print("result1 \(self.readWriteTask.read { self.name })")
            self.readWriteTask.write {
                self.name = "99999999"
            }
            print("result2 \(self.readWriteTask.read { self.name })")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            print("result3 \(self.readWriteTask.read { self.name })")
        }
    }
    
}
