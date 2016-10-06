//
//  RolloutSwiftObjectCreator.swift
//  Rollout
//
//  Created by Elad Cohen on 6/22/16.
//  Copyright © 2016 DeDoCo. All rights reserved.
//

import Foundation

@objc public class RolloutSwiftObjectCreator : NSObject {
    @objc public static func createIntArray(numbers : [Int]) -> Int {
        var array : Array<Int> = []
        numbers.forEach { (number) in
            array.append(number)
        }
        
        let arrayAddress = unsafeBitCast(array, Int.self)
        let ownerAddress = unsafeAddressOf(array._owner!)
        let refCount = UnsafeMutablePointer<Int32>(ownerAddress.advancedBy(sizeof(Int)))
        refCount.memory = refCount.memory + 4
        
        return arrayAddress
    }
    
    @objc public static func createAnyObjectArray(objects : [AnyObject]) -> Int {
        var array: Array<AnyObject> = []
        objects.forEach { (object) in
            array.append(object)
        }
        
        let arrayAddress = unsafeBitCast(array, Int.self)
        let ownerAddress = unsafeAddressOf(array._owner!)
        let refCount = UnsafeMutablePointer<Int32>(ownerAddress.advancedBy(sizeof(Int)))
        refCount.memory = refCount.memory + 4
        
        return arrayAddress
    }
    
    @objc public static func createStringIntDictionary(dictionary: Dictionary<String, Int>) -> Int {
        var newDictionary = Dictionary<String, Int>()
        
        dictionary.forEach { (key, value) in
            newDictionary[key] = value
        }
        
        let dictionaryAddress = unsafeBitCast(newDictionary, Int.self)
        //let dictionaryPointer = UnsafeMutablePointer<Int>(bitPattern: dictionaryAddress)
        
        let refCount = UnsafeMutablePointer<Int32>(bitPattern: dictionaryAddress + (sizeof(Int)))
        refCount.memory = refCount.memory + 4
        
        return dictionaryAddress
    }
}
