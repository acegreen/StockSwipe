//
//  XCTestCase+Extensions.swift
//  StockSwipeTests
//
//  Created by Ace Green on 2/29/20.
//  Copyright © 2020 StockSwipe. All rights reserved.
//

import XCTest
import OHHTTPStubs

/// Default timeout for expectations
let defaultTimeout: Double = 5

struct OHTTPStubsError {
    static let invalidFileType = NSError(domain: "OHTTPStubsError", code: 1, userInfo: [NSLocalizedDescriptionKey: "invalidFileType"])
    static let fileNotFound = NSError(domain: "OHTTPStubsError", code: 2, userInfo: [NSLocalizedDescriptionKey: "fileNotFound"])
}

extension XCTestCase {

    func mockResponse(for url: URL, queryParams params: [String: String]? = nil, response: @escaping OHHTTPStubsResponseBlock) {
        if let params = params {
            stub(condition: isPath(url.path) && containsQueryParams(params), response: response)
        } else {
            stub(condition: isPath(url.path), response: response)
        }
    }

    func mockResponse(for url: URL, queryParams params: [String: String]? = nil, withJSONFile filename: String, statusCode: Int = 200) {
        mockResponse(for: url, queryParams: params) { _ -> OHHTTPStubsResponse in

            guard (filename as NSString).pathExtension == "json" else {
                return OHHTTPStubsResponse(error: OHTTPStubsError.invalidFileType)
            }

            guard let filepath = OHPathForFile(filename, QueryTests.self) else {
                return OHHTTPStubsResponse(error: OHTTPStubsError.fileNotFound)
            }

            return OHHTTPStubsResponse(fileAtPath: filepath, statusCode: Int32(statusCode), headers: nil)
        }
    }

    func mockResponse(for url: URL, withJSON json: Any, statusCode: Int = 200) {
        mockResponse(for: url) { _ -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(jsonObject: json, statusCode: Int32(statusCode), headers: nil)
        }
    }

    func mockEmptyResponse(for url: URL, statusCode: Int = 200) {
        mockResponse(for: url) { _ -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(data: Data(count: 0), statusCode: Int32(statusCode), headers: nil)
        }
    }
}

extension XCTestCase {

    func object<T: Codable>(fromFile filename: String) -> T? {
        guard let json = getJSON(fromFileName: filename) else {
            XCTFail("can not access file \(filename).json")
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: json)
    }

    func getObject<T>(type: T.Type, fromFileName fileName: String) -> T? where T: Codable {
        guard let json = getJSON(fromFileName: fileName) else {
            XCTFail("can not access file \(fileName).json")
            return nil
        }
        do {
            return try? JSONDecoder().decode(type.self, from: json)
        }
    }

    func getJSON(fromFileName name: String, fileExtension: String = "json") -> Data? {
        if let url = URL(string: "acegreen" + ":" + String(8000) + "/" + name + "." + fileExtension), let fileContent = try? Data(contentsOf: url) {
            return fileContent
        } else {
            XCTFail("Error in reading the file \(name + "." + fileExtension) ")
        }
        return nil
    }

    func getRegDic(withId id: String, data: String, andDataType type: String) -> [String: String] {
        return ["id": id, "data": data, "dataType": type]
    }
}
