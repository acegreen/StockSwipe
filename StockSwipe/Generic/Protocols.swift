//
//  Protocols.swift
//  StockSwipe
//
//  Created by Ace Green on 4/3/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit
import Foundation

protocol SegueHandlerType {
    associatedtype SegueIdentifier: RawRepresentable
}

protocol CellType {
    associatedtype CellIdentifier: RawRepresentable
}

protocol DetectTags { }

protocol ReusableView: class {}

protocol Tintable { }