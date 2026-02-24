//
//  AnyDiffVMItem.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation
import UIKit

/// 类型擦除的Cell信息
struct AnyDiffVMItem: Hashable {
    static func == (lhs: AnyDiffVMItem, rhs: AnyDiffVMItem) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: AnyHashable
    let viewModel: ViewModelNode
    
    let cellReuseIdentifier: String
    
    let configure: (UICollectionViewCell) -> Void
    
    let sizeCalculator: (UICollectionViewCell, CGSize) -> CGSize
    
    init<CellType: DiffVMCellProtocol>(cellType: CellType.Type, cellViewModel: CellType.ViewModelType) {
        // cellType not be used
        self.id = cellViewModel
        self.viewModel = cellViewModel
        self.cellReuseIdentifier = CellType.reuseIdentifier
        self.configure = { cell in
            guard let cell = cell as? CellType else { return }
            cell.bind(to: cellViewModel)
        }
        self.sizeCalculator = { templateCell, containerSize in
            guard let cell = templateCell as? CellType else { return .zero }
            return cell.preferredSize(for: cellViewModel, within: containerSize)
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
