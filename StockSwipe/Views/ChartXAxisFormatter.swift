//
//  ChartXAxisFormatter.swift
//  StockSwipe
//
//  Created by Ace Green on 11/1/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import Foundation
import Charts

public class ChartXAxisFormatter: NSObject, IAxisValueFormatter {
    
    var entries: [String]
    /// Called when a value from an axis is formatted before being drawn.
    ///
    /// For performance reasons, avoid excessive calculations and memory allocations inside this method.
    ///
    /// - returns: The customized label that is drawn on the x-axis.
    /// - parameter value:           the value that is currently being drawn
    /// - parameter axis:            the axis that the value belongs to
    ///
    
    //swap the dates array with your x-axis-Strings
    init(entries: [String]){
        self.entries = entries
    }
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return String(entries[Int(value)])
    }
}
