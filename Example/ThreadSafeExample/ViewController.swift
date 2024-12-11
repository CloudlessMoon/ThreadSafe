//
//  ViewController.swift
//  ThreadSafeExample
//
//  Created by jiasong on 2024/5/30.
//

import UIKit
import ThreadSafe

class ViewController: UIViewController {
    
    private let concurrentQueue = DispatchQueue(label: "concurrent", attributes: .concurrent)
    
    private let readWriteTask = ReadWriteTask(label: "test", attributes: .concurrent)
    private let otherReadWriteTask = ReadWriteTask(label: "other-test", attributes: .concurrent)
    
    private let mainThreadTask = MainThreadTask.default
    
    @UnfairLockValueWrapper
    private var readWriteCount: Int = 0 {
        didSet {
            print("readWriteCount \(self.readWriteCount)")
        }
    }
    
    private var readWriteName = "0"
    
    @UnfairLockValueWrapper
    private var mainThreadCount: Int = 0 {
        didSet {
            assert(self.mainThreadCount - oldValue == 1)
            print("mainThreadCount \(self.mainThreadCount)")
        }
    }
    
    private var mainThreadName = "0"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.testReadWriteTask()
        self.testMainThreadTask()
    }
    
}

extension ViewController {
    
    func testReadWriteTask() {
        let count = 1000
        for item in 1...count {
            self.concurrentQueue.async {
                _ = self.readWriteTask.read { defer { self.readWriteCount += 1 }; return self.readWriteName }
                
                self.readWriteTask.write {
                    self.readWriteCount += 1
                    
                    self.readWriteName = "\(item)"
                    
                    _ = self.readWriteTask.read { defer { self.readWriteCount += 1 }; return self.readWriteName }
                    
                    self.readWriteTask.asyncWrite {
                        self.readWriteCount += 1
                        
                        self.readWriteName = "\(item)"
                    }
                    
                    self.otherReadWriteTask.write {
                        _ = self.readWriteTask.read { defer { self.readWriteCount += 1 }; return self.readWriteName }
                        
                        self.readWriteTask.asyncWrite {
                            self.readWriteCount += 1
                            
                            self.readWriteName = "\(item)"
                            
                            self.readWriteTask.write {
                                self.readWriteCount += 1
                                
                                self.readWriteName = "\(item)"
                            }
                        }
                        self.readWriteTask.write {
                            self.readWriteCount += 1
                            
                            self.readWriteName = "\(item)"
                            
                            _ = self.readWriteTask.read { defer { self.readWriteCount += 1 }; return self.readWriteName }
                            
                            self.readWriteTask.write {
                                self.readWriteCount += 1
                                
                                _ = self.readWriteTask.read { defer { self.readWriteCount += 1 }; return self.readWriteName }
                                
                                self.readWriteName = "\(item)"
                            }
                        }
                    }
                    
                    self.readWriteTask.write {
                        self.readWriteCount += 1
                        
                        _ = self.readWriteTask.read { defer { self.readWriteCount += 1 }; return self.readWriteName }
                        
                        self.readWriteName = "\(item)"
                        
                        _ = self.readWriteTask.read { defer { self.readWriteCount += 1 }; return self.readWriteName }
                    }
                }
                
                _ = self.readWriteTask.read { defer { self.readWriteCount += 1 }; return self.readWriteName }
            }
            
            self.concurrentQueue.async {
                _ = self.readWriteTask.read { defer { self.readWriteCount += 1 }; return self.readWriteName }
                
                _ = self.readWriteTask.read { defer { self.readWriteCount += 1 }; return self.readWriteName }
                
                self.readWriteTask.asyncWrite {
                    self.readWriteCount += 1
                    
                    _ = self.readWriteTask.read { defer { self.readWriteCount += 1 }; return self.readWriteName }
                    
                    self.readWriteName = "\(item)"
                    
                    self.otherReadWriteTask.write {
                        self.readWriteTask.asyncWrite {
                            self.readWriteCount += 1
                            
                            _ = self.readWriteTask.read { defer { self.readWriteCount += 1 }; return self.readWriteName }
                            
                            self.readWriteName = "\(item)"
                        }
                        self.readWriteTask.write {
                            self.readWriteCount += 1
                            
                            self.readWriteName = "\(item)"
                            
                            _ = self.readWriteTask.read { defer { self.readWriteCount += 1 }; return self.readWriteName }
                        }
                    }
                    
                    self.readWriteTask.write {
                        self.readWriteCount += 1
                        
                        self.readWriteName = "\(item)"
                        
                        _ = self.readWriteTask.read { defer { self.readWriteCount += 1 }; return self.readWriteName }
                    }
                }
                
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            print("readWrite result1 \(self.readWriteTask.read { self.readWriteName })")
            self.readWriteTask.write {
                self.readWriteName = "99999999"
            }
            print("readWrite result2 \(self.readWriteTask.read { self.readWriteName })")
        }
    }
    
}

extension ViewController {
    
    func testMainThreadTask() {
        let count = 1000
        for item in 1...count {
            self.concurrentQueue.async {
                self.mainThreadTask.sync {
                    self.mainThreadCount += 1
                    
                    self.mainThreadName = "\(item)"
                    
                    self.mainThreadTask.async {
                        self.mainThreadCount += 1
                        
                        self.mainThreadName = "\(item)"
                        
                        self.mainThreadTask.sync {
                            self.mainThreadCount += 1
                            
                            self.mainThreadName = "\(item)"
                        }
                    }
                }
                
                self.mainThreadTask.async {
                    self.mainThreadCount += 1
                    
                    self.mainThreadName = "\(item)"
                    
                    self.mainThreadTask.sync {
                        self.mainThreadCount += 1
                        
                        self.mainThreadName = "\(item)"
                    }
                }
            }
            self.mainThreadTask.sync {
                self.mainThreadCount += 1
                
                self.mainThreadName = "\(item)"
                
                self.mainThreadTask.sync {
                    self.mainThreadCount += 1
                    
                    self.mainThreadName = "\(item)"
                }
            }
            
            self.mainThreadTask.sync {
                self.mainThreadCount += 1
                
                self.mainThreadName = "\(item)"
            }
            
            DispatchQueue.global().async {
                self.mainThreadTask.sync {
                    self.title = "\(item)"
                }
                
                self.mainThreadTask.async {
                    self.title = "\(item)"
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            print("mainThread result1 \(self.mainThreadTask.sync { self.mainThreadName })")
            self.mainThreadTask.sync {
                self.mainThreadName = "99999999"
            }
            print("mainThread result2 \(self.mainThreadTask.sync { self.mainThreadName })")
            
            print("mainThread title \(self.mainThreadTask.sync { self.title ?? "" })")
        }
    }
    
}
