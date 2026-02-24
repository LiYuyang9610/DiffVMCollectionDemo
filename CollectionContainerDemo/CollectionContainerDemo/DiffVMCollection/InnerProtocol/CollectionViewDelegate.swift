//
//  CollectionViewDelegate.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation
import UIKit

/// 回传 CollectionBridger 调用
protocol CollectionViewDelegate: AnyObject {
    var sections: [DiffVMSection] { get }
    func sizeForItem(at indexPath: IndexPath) -> CGSize
    func selectItem(at indexPath: IndexPath, with itemId: AnyHashable)
    func insetForSection(at index: Int) -> UIEdgeInsets
    func minimumLineSpacingForSection(at index: Int) -> CGFloat
    func minimumInteritemSpacingForSection(at index: Int) -> CGFloat
}
