//
//  StockSwipeTests.swift
//  StockSwipeTests
//
//  Created by Ace Green on 2015-05-23.
//  Copyright (c) 2015 Richard Burdish. All rights reserved.
//

import XCTest
import OHHTTPStubs
@testable import StockSwipe

class QueryTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testFetchEODHistoricalResult() {

        let symbol = "COST"
        let today = Date()
           let oneYearAgp = Date.dateBySubtractingDays(today, numberOfDays: -365)
           let query = "https://eodhistoricaldata.com/api/eod/" + symbol +
               "?from=" + oneYearAgp.dateFormattedString() +
               "&to=" + today.dateFormattedString() +
               "&api_token=" + Constants.APIKeys.EodHistorcalData.key() +
               "&period=d" +
               "&fmt=json"

        guard let queryURL = URL(string: query.URLEncodedString() ?? "") else { return XCTFail("URL query invalid") }

//        mockResponse(for: queryURL, withJSONFile: "EODHistoricalResult.json")

        let expectation = self.expectation(description: "expectation")

        QueryHelper.sharedInstance.queryEODHistorical(for: symbol) { eodHistoricalResult in
            do {
                let eodHistoricalResult = try eodHistoricalResult()
                let result = eodHistoricalResult.first
                XCTAssertNotNil(result?.close == 219.44)
                expectation.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        waitForExpectations(timeout: defaultTimeout, handler: nil)
    }

      func testFetchEODFundamentalsResult() {

            let symbol = "COST"
            let today = Date()
               let oneYearAgp = Date.dateBySubtractingDays(today, numberOfDays: -365)
               let query = "https://eodhistoricaldata.com/api/eod/" + symbol +
                   "?from=" + oneYearAgp.dateFormattedString() +
                   "&to=" + today.dateFormattedString() +
                   "&api_token=" + Constants.APIKeys.EodHistorcalData.key() +
                   "&period=d" +
                   "&fmt=json"

            guard let queryURL = URL(string: query.URLEncodedString() ?? "") else { return XCTFail("URL query invalid") }

    //        mockResponse(for: queryURL, withJSONFile: "EODFundamentalsResult.json")

            let expectation = self.expectation(description: "expectation")

            QueryHelper.sharedInstance.queryEODFundamentals(for: symbol) { eodFundamentalsResult in
                do {
                    let eodFundamentalsResult = try eodFundamentalsResult()
                    XCTAssertNotNil(eodFundamentalsResult.general.code == symbol)
                    expectation.fulfill()
                } catch {
                    XCTFail(error.localizedDescription)
                }
            }

            waitForExpectations(timeout: defaultTimeout, handler: nil)
        }
}
