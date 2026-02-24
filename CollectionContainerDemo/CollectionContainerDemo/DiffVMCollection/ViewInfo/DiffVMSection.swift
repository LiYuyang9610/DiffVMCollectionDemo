//
//  DiffVMSection.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation
import UIKit

/// Section层级的信息
struct DiffVMSection: Hashable {
    static func == (lhs: DiffVMSection, rhs: DiffVMSection) -> Bool {
        lhs.items == rhs.items
    }
    
    let title: String
    let items: [AnyDiffVMItem]
    
    var inset: UIEdgeInsets = .zero
    var minimumLineSpacing: CGFloat = .zero
    var minimumInteritemSpacing: CGFloat = .zero
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(items)
    }
}
