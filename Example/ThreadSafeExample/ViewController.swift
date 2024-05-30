//
//  ViewController.swift
//  ThreadSafeExample
//
//  Created by jiasong on 2024/5/30.
//

import UIKit
import ThreadSafe

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let readWriteTask = ReadWriteTask(label: "test")
        
        var name = "0"
        
        let count = 10
        for item in 1...count {
            DispatchQueue.global().async {
                name = "1"
                
                let name1 = readWriteTask.read { name }
                print("readWriteTask1 read1 \(name1)")
                
                readWriteTask.write {
                    name = "\(item)"
                    print("readWriteTask1 write1 \(name)")
                    
                    let name1 = readWriteTask.read { name }
                    print("readWriteTask1 read1 \(name1)")
                    
                    readWriteTask.write {
                        name = "22_\(item)"
                        print("readWriteTask1 write2 \(name)")
                        
                        readWriteTask.write {
                            name = "22_\(item)"
                            print("readWriteTask1 write2 \(name)")
                            
                            let name1 = readWriteTask.read { name }
                            print("readWriteTask1 read1 \(name1)")
                        }
                        
                        let name1 = readWriteTask.read { name }
                        print("readWriteTask1 read1 \(name1)")
                    }
                }
                
                let name2 = readWriteTask.read {
                    return name
                }
                print("readWriteTask1 read \(name2)")
            }
            
            DispatchQueue.global().async {
                print("readWriteTask1 read1 \(name)")
                
                let name1 = readWriteTask.read {
                    //                    let name2 = readWriteTask.write {
                    //                        return name
                    //                    }
                    return name
                }
                print("readWriteTask1 read \(name1)")
                
                let name2 = readWriteTask.read {
                    return name
                }
                print("readWriteTask1 read \(name2)")
                
                let name3 = readWriteTask.read {
                    return name
                }
                print("readWriteTask1 read \(name3)")
                
                let name4 = readWriteTask.read {
                    return name
                }
                print("readWriteTask1 read \(name4)")
                
                readWriteTask.write {
                    name = "\(item)"
                    print("readWriteTask1 write1 \(name)")
                    
                    let name1 = readWriteTask.read { name }
                    print("readWriteTask1 read1 \(name1)")
                    
                    readWriteTask.write {
                        name = "22_\(item)"
                        print("readWriteTask1 write2 \(name)")
                        
                        readWriteTask.write {
                            name = "22_\(item)"
                            print("readWriteTask1 write2 \(name)")
                            
                            let name1 = readWriteTask.read { name }
                            print("readWriteTask1 read1 \(name1)")
                        }
                    }
                    
                    print("readWriteTask1 write1 \(name)")
                }
                
                let name5 = readWriteTask.read { name }
                print("readWriteTask1 read1 \(name5)")
            }
        }
    }

}
