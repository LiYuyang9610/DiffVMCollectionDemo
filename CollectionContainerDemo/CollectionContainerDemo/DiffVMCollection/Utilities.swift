//
//  Utilities.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation
import UIKit

struct IndexPathWrapper: Hashable, Comparable {
    static func < (lhs: IndexPathWrapper, rhs: IndexPathWrapper) -> Bool {
        IndexPath(lhs) < IndexPath(rhs)
    }
    
    let section: Int
    let item: Int
    
    init(section: Int, item: Int) {
        self.section = section
        self.item = item
    }
    
    init(_ indexPath: IndexPath) {
        self.section = indexPath.section
        self.item = indexPath.item
    }
}

extension IndexPath {
    init(_ wrapper: IndexPathWrapper) {
        self = IndexPath(item: wrapper.item, section: wrapper.section)
    }
}

struct CGSizeWrapper: Hashable {
    let width: Double
    let height: Double
    
    init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
    
    init(_ size: CGSize) {
        self.width = size.width
        self.height = size.height
    }
}

extension CGSize {
    init(_ wrapper: CGSizeWrapper) {
        self = CGSize(width: wrapper.width, height: wrapper.height)
    }
}

struct CGRectWrapper: Hashable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    
    var minX: Double { x }
    var minY: Double { y }
    var maxX: Double { x + width }
    var maxY: Double { y + height }
    
    init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
    
    init(_ rect: CGRect) {
        self.x = rect.minX
        self.y = rect.minY
        self.width = rect.width
        self.height = rect.height

    }
}

extension CGRect {
    init(_ wrapper: CGRectWrapper) {
        self = CGRect(x: wrapper.x, y: wrapper.y, width: wrapper.width, height: wrapper.height)
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
