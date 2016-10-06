//
// Created by Sergey Ilyevsky on 26/07/2016.
// Copyright (c) 2016 DeDoCo. All rights reserved.
//

import Foundation
import Rollout

class RolloutSwiftType<T>
{
    var value : T
    init(value: T) {
        self.value = value
    }
    
    func get() -> T {
        return value
    }
}

func initWithSwiftTypeWrapper<T>(value: T) -> RolloutSwiftTypeWrapper {
    let swiftType = RolloutSwiftType(value: value)
    let swiftWrapper = RolloutSwiftTypeWrapper(object: swiftType, className: "\(T.self)")
    return swiftWrapper
}

func cast<T, U>(value: T, type: U.Type) -> U {
    return value as! U
}

func extractFromTypeWrapper<T>(typeWrapper: Any) -> T {
    return extractFromTypeWrapper(typeWrapper as! RolloutTypeWrapper)
}

func extractFromTypeWrapper<T>(typeWrapper: RolloutTypeWrapper) -> T {
    
    if (RolloutTypePointer == typeWrapper.type && typeWrapper.pointerValue == UnsafeMutablePointer<Void>(nil)) {
        return cast(Int(""), type: T.self)
    }
    else if (T.self == Int.self || T.self == Int?.self) {
        return typeWrapper.longValue() as! T
    }
    else if (T.self == UInt.self || T.self == UInt?.self) {
        return typeWrapper.uLongValue() as! T
    }
    else if (T.self == Int8.self || T.self == Int8?.self) {
        return typeWrapper.sCharValue() as! T
    }
    else if (T.self == UInt8.self || T.self == UInt8?.self) {
        return typeWrapper.uCharValue() as! T
    }
    else if (T.self == Int16.self || T.self == Int16?.self) {
        return typeWrapper.shortValue() as! T
    }
    else if (T.self == UInt16.self || T.self == UInt16?.self) {
        return typeWrapper.uShortValue() as! T
    }
    else if (T.self == Int32.self || T.self == Int32?.self) {
        return typeWrapper.intValue() as! T
    }
    else if (T.self == UInt32.self || T.self == UInt32?.self) {
        return typeWrapper.uIntValue() as! T
    }
    else if (T.self == Int64.self || T.self == Int64?.self) {
        return typeWrapper.longLongValue() as! T
    }
    else if (T.self == UInt64.self || T.self == UInt64?.self) {
        return typeWrapper.uLongLongValue() as! T
    }
    else if (T.self == Float.self || T.self == Float?.self) {
        return typeWrapper.floatValue() as! T
    }
    else if (T.self == Double.self || T.self == Double?.self) {
        return typeWrapper.doubleValue() as! T
    }
    else if (T.self == Bool.self || T.self == Bool?.self) {
        return typeWrapper.boolValue() as! T
    }
    else if (T.self == String.self || T.self == String?.self) {
        return typeWrapper.objCObjectPointerValue as! T
    }
    else if let swiftWrapper = typeWrapper.objCObjectPointerValue as? RolloutSwiftTypeWrapper {
        let swiftType = swiftWrapper.object as! RolloutSwiftType<T>
        return swiftType.get()
    }
    
    return typeWrapper.objCObjectPointerValue as! T
}

func initWithTypeWrapper<T>(value: T) -> RolloutTypeWrapper {
    
    if (T.self == Void.self) {
        return RolloutTypeWrapper.init(void: ())
    }
    else if (cast(value, type: (T?).self)  == nil) {
        return RolloutTypeWrapper.init(pointer: UnsafeMutablePointer<Void>(nil))
    }
    else if (T.self == Int.self || T.self == Int?.self) {
        return RolloutTypeWrapper.init(long: value as! Int)
    }
    else if (T.self == UInt.self || T.self == UInt.self) {
        return RolloutTypeWrapper.init(ULong: value as! UInt)
    }
    else if (T.self == Int8.self || T.self == Int8?.self) {
        return RolloutTypeWrapper.init(SChar: value as! Int8)
    }
    else if (T.self == UInt8.self || T.self == UInt8?.self ) {
        return RolloutTypeWrapper.init(UChar: value as! UInt8)
    }
    else if (T.self == Int16.self || T.self == Int16?.self) {
        return RolloutTypeWrapper.init(short: value as! Int16)
    }
    else if (T.self == UInt16.self || T.self == UInt16?.self) {
        return RolloutTypeWrapper.init(UShort: value as! UInt16)
    }
    else if (T.self == Int32.self || T.self == Int32?.self) {
        return RolloutTypeWrapper.init(int: value as! Int32)
    }
    else if (T.self == UInt32.self || T.self == UInt32?.self) {
        return RolloutTypeWrapper.init(UInt: value as! UInt32)
    }
    else if (T.self == Int64.self || T.self == Int64?.self) {
        return RolloutTypeWrapper.init(longLong: value as! Int64)
    }
    else if (T.self == UInt64.self || T.self == UInt64?.self) {
        return RolloutTypeWrapper.init(ULongLong: value as! UInt64)
    }
    else if (T.self == Float.self || T.self == Float?.self) {
        return RolloutTypeWrapper.init(float: value as! Float)
    }
    else if (T.self == Double.self || T.self == Double?.self) {
        return RolloutTypeWrapper.init(double: value as! Double)
    }
    else if (T.self == Bool.self || T.self == Bool?.self) {
        return RolloutTypeWrapper.init(bool: value as! Bool)
    }
    else if (T.self == String.self || T.self == String?.self) {
        return RolloutTypeWrapper.init(objCObjectPointer: value as! String)
    }
    else if let objcValue = value as? NSObject {
        return RolloutTypeWrapper.init(objCObjectPointer: objcValue)
    }
    
    let swiftWrapper = initWithSwiftTypeWrapper(value)
    return RolloutTypeWrapper(objCObjectPointer: swiftWrapper)
}

@inline(__always) func Rollout_shouldPatch(tweakData:RolloutSwiftTweakData?) -> Bool {
    if tweakData != nil && tweakData!.shouldPatchInTheCurrentThread {
        return true
    }
    return false
}

func Rollout_invoke(tweakData:RolloutSwiftTweakData, target: AnyObject, arguments: [RolloutTypeWrapper], origClosure: (NSArray!)->Void) -> Void {
    let context = RolloutInvocationContext(target: target, tweakId: tweakData.tweakId, arguments: arguments, swiftTweakData: tweakData)
    tweakData.invocation.invokeWithContext(context, originalMethodWrapper: {args in
        origClosure(args)
        return RolloutTypeWrapper.init(void: ())
    })
}

func Rollout_invokeReturn<T>(tweakData:RolloutSwiftTweakData, target: AnyObject, arguments: [RolloutTypeWrapper], origClosure: (NSArray!)->T) -> T {
    let context = RolloutInvocationContext(target: target, tweakId: tweakData.tweakId, arguments: arguments, swiftTweakData: tweakData)
    let result = tweakData.invocation.invokeWithContext(context, originalMethodWrapper: {args in
        let originalResult = origClosure(args)
        return initWithTypeWrapper(originalResult)
    })
    
    return extractFromTypeWrapper(result)
}
