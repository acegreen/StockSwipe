//
//  Cache.swift
//  CacheDemo
//
//  Created by Nguyen Cong Huy on 7/4/16.
//  Copyright © 2016 Nguyen Cong Huy. All rights reserved.
//

import UIKit

public enum ImageFormat {
    case unknown, png, jpeg
}

open class DataCache {
    static let cacheDirectoryPrefix = "com.nch.cache."
    static let ioQueuePrefix = "com.nch.queue."
    static let defaultMaxCachePeriodInSecond: TimeInterval = 60 * 60 * 24 * 7         // a week
    
    open static var defaultCache = DataCache(name: "default")
    
    var cachePath: String
    
    let memCache = NSCache()
    let ioQueue: DispatchQueue
    var fileManager = FileManager()
    
    /// Name of cache
    open var name: String = ""
    
    /// Life time of disk cache, in second. Default is a week
    open var maxCachePeriodInSecond = DataCache.defaultMaxCachePeriodInSecond
    
    /// Size is allocated for disk cache, in byte. 0 mean no limit. Default is 0
    open var maxDiskCacheSize: UInt = 0
    
    /// Specify distinc name param, it represents folder name for disk cache
    public init(name: String, path: String? = nil) {
        self.name = name
        
        cachePath = path ?? NSSearchPathForDirectoriesInDomains(.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first!
        cachePath = (cachePath as NSString).appendingPathComponent(DataCache.cacheDirectoryPrefix + name)
        
        ioQueue = DispatchQueue(label: DataCache.ioQueuePrefix + name, attributes: DispatchQueue.Attributes.concurrent)
        
        ioQueue.async { 
            self.fileManager = FileManager()
        }
        
        #if !os(OSX) && !os(watchOS)
            NotificationCenter.default.addObserver(self, selector: #selector(DataCache.cleanExpiredDiskCache), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(DataCache.cleanExpiredDiskCache), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        #endif
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

    // MARK: Store

extension DataCache {
    
    /// Write data for key. This is an async operation.
    public func writeData(_ data: Data, forKey key: String) {
        memCache.setObject(data, forKey: key)
        writeDataToDisk(data, key: key)
    }
    
    func writeDataToDisk(_ data: Data, key: String) {
        ioQueue.async { 
            if self.fileManager.fileExists(atPath: self.cachePath) == false {
                do {
                    try self.fileManager.createDirectory(atPath: self.cachePath, withIntermediateDirectories: true, attributes: nil)
                }
                catch {
                    print("Error while creating cache folder")
                }
            }
            
            self.fileManager.createFile(atPath: self.cachePathForKey(key), contents: data, attributes: nil)
        }
    }
    
    /// Read data for key
    public func readDataForKey(_ key:String) -> Data? {
        var data = memCache.object(forKey: key) as? Data
        
        if data == nil {
            if let dataFromDisk = readDataFromDiskForKey(key) {
                data = dataFromDisk
                memCache.setObject(dataFromDisk, forKey: key)
            }
        }
        
        return data
    }
    
    /// Read data from disk for key
    public func readDataFromDiskForKey(_ key: String) -> Data? {
        return self.fileManager.contents(atPath: cachePathForKey(key))
    }
    
    
    // MARK: Read & write utils
    
    
    /// Write an object for key. This object must inherit from `NSObject` and implement `NSCoding` protocol. `String`, `Array`, `Dictionary` conform to this method.
    ///
    /// NOTE: Can't write `UIImage` with this method. Please use `writeImage(_:forKey:)` to write an image
    public func writeObject(_ value: NSCoding, forKey key: String) {
        let data = NSKeyedArchiver.archivedData(withRootObject: value)
        writeData(data, forKey: key)
    }
    
    /// Read an object for key. This object must inherit from `NSObject` and implement NSCoding protocol. `String`, `Array`, `Dictionary` conform to this method
    public func readObjectForKey(_ key: String) -> NSObject? {
        let data = readDataForKey(key)
        
        if let data = data {
            return NSKeyedUnarchiver.unarchiveObject(with: data) as? NSObject
        }
        
        return nil
    }
    
    /// Read a string for key
    public func readStringForKey(_ key: String) -> String? {
        return readObjectForKey(key) as? String
    }
    
    /// Read an array for key
    public func readArrayForKey(_ key: String) -> Array<AnyObject>? {
        return readObjectForKey(key) as? Array<AnyObject>
    }
    
    /// Read a dictionary for key
    public func readDictionaryForKey(_ key: String) -> Dictionary<String, AnyObject>? {
        return readObjectForKey(key) as? Dictionary<String, AnyObject>
    }
    
    // MARK: Read & write image
    
    /// Write image for key. Please use this method to write an image instead of `writeObject(_:forKey:)`
    public func writeImage(_ image: UIImage, forKey key: String, format: ImageFormat? = nil) {
        var data: Data? = nil
        
        if let format = format , format == .png {
            data = UIImagePNGRepresentation(image)
        }
        else {
            data = UIImageJPEGRepresentation(image, 0.9)
        }
        
        if let data = data {
            writeData(data, forKey: key)
        }
    }
    
    /// Read image for key. Please use this method to write an image instead of `readObjectForKey(_:)`
    public func readImageForKey(_ key: String) -> UIImage? {
        let data = readDataForKey(key)
        if let data = data {
            return UIImage(data: data, scale: 1.0)
        }
        
        return nil
    }
}

// MARK: Utils

extension DataCache {
    
    /// Check if has data on disk
    public func hasDataOnDiskForKey(_ key: String) -> Bool {
        return self.fileManager.fileExists(atPath: self.cachePathForKey(key))
    }
    
    /// Check if has data on mem
    public func hasDataOnMemForKey(_ key: String) -> Bool {
        return (memCache.object(forKey: key) != nil)
    }
}

// MARK: Clean

extension DataCache {
    
    /// Clean all mem cache and disk cache. This is an async operation.
    public func cleanAll() {
        cleanMemCache()
        cleanDiskCache()
    }
    
    /// Clean cache by key. This is an async operation.
    public func cleanByKey(_ key: String) {
        memCache.removeObject(forKey: key)
        
        ioQueue.async { 
            do {
                try self.fileManager.removeItem(atPath: self.cachePathForKey(key))
            } catch {}
        }
    }
    
    func cleanMemCache() {
        memCache.removeAllObjects()
    }
    
    func cleanDiskCache() {
        ioQueue.async {
            do {
                try self.fileManager.removeItem(atPath: self.cachePath)
            } catch {}
        }
    }
    
    /// Clean expired disk cache. This is an async operation.
    @objc public func cleanExpiredDiskCache() {
        cleanExpiredDiskCacheWithCompletionHander(nil)
    }
    
    // This method is from Kingfisher
    /**
     Clean expired disk cache. This is an async operation.
     
     - parameter completionHandler: Called after the operation completes.
     */
    public func cleanExpiredDiskCacheWithCompletionHander(_ completionHandler: (()->())?) {
        
        // Do things in cocurrent io queue
        ioQueue.async(execute: { () -> Void in
            
            var (URLsToDelete, diskCacheSize, cachedFiles) = self.travelCachedFiles()
            
            for fileURL in URLsToDelete {
                do {
                    try self.fileManager.removeItem(at: fileURL)
                } catch {}
            }
            
            if self.maxDiskCacheSize > 0 && diskCacheSize > self.maxDiskCacheSize {
                let targetSize = self.maxDiskCacheSize / 2
                
                // Sort files by last modify date. We want to clean from the oldest files.
                let sortedFiles = cachedFiles.keysSortedByValue {
                    resourceValue1, resourceValue2 -> Bool in
                    
                    if let date1 = resourceValue1[URLResourceKey.contentModificationDateKey] as? Date,
                        let date2 = resourceValue2[URLResourceKey.contentModificationDateKey] as? Date {
                        return date1.compare(date2) == .orderedAscending
                    }
                    // Not valid date information. This should not happen. Just in case.
                    return true
                }
                
                for fileURL in sortedFiles {
                    
                    do {
                        try self.fileManager.removeItem(at: fileURL)
                    } catch {}
                    
                    URLsToDelete.append(fileURL)
                    
                    if let fileSize = cachedFiles[fileURL]?[URLResourceKey.totalFileAllocatedSizeKey] as? NSNumber {
                        diskCacheSize -= fileSize.uintValue
                    }
                    
                    if diskCacheSize < targetSize {
                        break
                    }
                }
            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                completionHandler?()
            })
        })
    }
}

// MARK: Helpers

extension DataCache {
    
    // This method is from Kingfisher
    func travelCachedFiles() -> (URLsToDelete: [URL], diskCacheSize: UInt, cachedFiles: [URL: [AnyHashable: Any]]) {
        
        let diskCacheURL = URL(fileURLWithPath: cachePath)
        let resourceKeys = [URLResourceKey.isDirectoryKey, URLResourceKey.contentModificationDateKey, URLResourceKey.totalFileAllocatedSizeKey]
        let expiredDate = Date(timeIntervalSinceNow: -self.maxCachePeriodInSecond)
        
        var cachedFiles = [URL: [AnyHashable: Any]]()
        var URLsToDelete = [URL]()
        var diskCacheSize: UInt = 0
        
        if let fileEnumerator = self.fileManager.enumerator(at: diskCacheURL, includingPropertiesForKeys: resourceKeys, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles, errorHandler: nil),
            let urls = fileEnumerator.allObjects as? [URL] {
            for fileURL in urls {
                
                do {
                    let resourceValues = try (fileURL as NSURL).resourceValues(forKeys: resourceKeys)
                    // If it is a Directory. Continue to next file URL.
                    if let isDirectory = resourceValues[URLResourceKey.isDirectoryKey] as? NSNumber {
                        if isDirectory.boolValue {
                            continue
                        }
                    }
                    
                    // If this file is expired, add it to URLsToDelete
                    if let modificationDate = resourceValues[URLResourceKey.contentModificationDateKey] as? Date {
                        if (modificationDate as NSDate).laterDate(expiredDate) == expiredDate {
                            URLsToDelete.append(fileURL)
                            continue
                        }
                    }
                    
                    if let fileSize = resourceValues[URLResourceKey.totalFileAllocatedSizeKey] as? NSNumber {
                        diskCacheSize += fileSize.uintValue
                        cachedFiles[fileURL] = resourceValues
                    }
                } catch _ {
                }
            }
        }
        
        return (URLsToDelete, diskCacheSize, cachedFiles)
    }
    
    func cachePathForKey(_ key: String) -> String {
        let fileName = key.kf_MD5
        return (cachePath as NSString).appendingPathComponent(fileName)
    }
}
