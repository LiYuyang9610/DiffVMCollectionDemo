//
//  DiffVMCollectionContainer.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation
import UIKit

/// 接入方使用的View, 声明类型时需要把可能出现的Cell类型列举做隐式注册
class DiffVMCollectionContainer<LayoutType: UICollectionViewLayout, each CellType: DiffVMCellProtocol>: CollectionViewDelegate {
    
    let collectionView: UICollectionView
    
    private var templateCells: [String : UICollectionViewCell] = [:] // 目前的算高是以模板cell的方式获得
    
    private let collectionHandler: CollectionBridger = CollectionBridger()
    
    private var currentSections: [DiffVMSection] = []
    
    var sections: [DiffVMSection] { currentSections }
    
    let viewModel = DiffVMCollectionViewModel()
    
    init(_ layout: LayoutType, cellTypes: repeat (each CellType).Type) {
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionHandler.delegate = self
        collectionView.delegate = collectionHandler
        collectionView.dataSource = collectionHandler
        for cellType in repeat (each cellTypes) {
            collectionView.register(cellType, forCellWithReuseIdentifier: cellType.reuseIdentifier)
            templateCells[cellType.reuseIdentifier] = cellType.init(frame: .zero)
        }
        viewModel.transform()
    }
    
    func apply(_ updatedSections: [DiffVMSection], animated: Bool, completion: ((Bool) -> Void)? = nil) {
        guard updatedSections != currentSections else {
            completion?(true)
            return
        }
        viewModel.childrenViewModels = updatedSections.map({ diffVMSection in
            let sectionViewModel = DiffVMSectionViewModel(diffVMSection.items.map(\.viewModel))
            sectionViewModel.parentViewModel = viewModel
            sectionViewModel.transform()
            return sectionViewModel
        })
        
        let outdatedSections = currentSections
        
        // MARK: - diff算法由AI生成 -
        
        // 1. 计算 Section 的 Diff
        let sectionDiff = updatedSections.difference(from: outdatedSections)
        // 收集 Section 的变更
        var sectionInserts: IndexSet = []
        var sectionDeletes: IndexSet = []
        // 这里的 changes 包含了 .insert 和 .remove
        for change in sectionDiff {
            switch change {
            case .remove(let offset, _, _):
                sectionDeletes.insert(offset)
            case .insert(let offset, _, _):
                sectionInserts.insert(offset)
            }
        }
        // 2. 准备 Item 的 Diff
        // 注意：我们只能对“既没被删除、也不是新插入”的 Section 进行 Item Diff
        // 因为被删除的 Section 不需要管 Item，新插入的 Section 全部 Item 都是 Insert
        var itemInserts: [IndexPath] = []
        var itemDeletes: [IndexPath] = []
        // 找出“保留下来”的 Section 索引映射关系
        // key: oldIndex, value: newIndex
        var oldToNewSectionMap: [Int: Int] = [:]
        // 模拟应用 Section Diff 后的索引变化
        // 这是一个简化的映射算法，假设相对顺序保持一致（通常 Diff 算法会保持相对顺序）
        // 更严谨的做法是使用 inferringMoves，但这里我们用简单的遍历匹配
        // 遍历旧 Section，看它在新数组里的位置
        for (oldIndex, oldSection) in outdatedSections.enumerated() {
            // 如果这个 Section 被删了，跳过
            if sectionDeletes.contains(oldIndex) { continue }
            // 在新数组中找到对应的 Section (通过 Hashable/Equatable)
            // 注意：这里假设 Section 没有重复。如果有重复，需要更复杂的 ID 匹配
            if let newIndex = updatedSections.firstIndex(of: oldSection) {
                oldToNewSectionMap[oldIndex] = newIndex
                // 计算这个 Section 内部 Item 的 Diff
                let oldItems = oldSection.items
                let newItems = updatedSections[newIndex].items
                let itemDiff = newItems.difference(from: oldItems)
                for change in itemDiff {
                    switch change {
                    case .remove(let offset, _, _):
                        // 删除使用的是 Old IndexPath
                        itemDeletes.append(IndexPath(item: offset, section: oldIndex))
                    case .insert(let offset, _, _):
                        // 插入使用的是 New IndexPath
                        itemInserts.append(IndexPath(item: offset, section: newIndex))
                    }
                }
            }
        }
        // 3. 执行 Batch Updates
        let updateBlock: () -> Void = {
            self.collectionView.performBatchUpdates({
                self.currentSections = updatedSections
                // A. 处理 Section 变更
                if !sectionDeletes.isEmpty {
                    self.collectionView.deleteSections(sectionDeletes)
                }
                if !sectionInserts.isEmpty {
                    self.collectionView.insertSections(sectionInserts)
                }
                // B. 处理 Item 变更
                if !itemDeletes.isEmpty {
                    self.collectionView.deleteItems(at: itemDeletes)
                }
                if !itemInserts.isEmpty {
                    self.collectionView.insertItems(at: itemInserts)
                }
            }, completion: completion)
        }
        if animated {
            updateBlock()
        } else {
            UIView.performWithoutAnimation {
                updateBlock()
            }
        }
    }
    
    func sizeForItem(at indexPath: IndexPath) -> CGSize {
        guard let item = currentSections[safe: indexPath.section]?.items[safe: indexPath.item] else { return .zero }
        let containerSize = CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
        guard let templateCell = templateCells[item.cellReuseIdentifier] else { return .zero }
        return item.sizeCalculator(templateCell, containerSize)
    }
    
    func selectItem(at indexPath: IndexPath, with itemId: AnyHashable) {
        viewModel.notifyParent(for: DiffVMEventHandler.self) { $0.selectItem(at: indexPath, with: itemId) }
    }
    
    func insetForSection(at index: Int) -> UIEdgeInsets {
        guard let section = currentSections[safe: index] else { return .zero }
        return section.inset
    }
    
    func minimumLineSpacingForSection(at index: Int) -> CGFloat {
        guard let section = currentSections[safe: index] else { return .zero }
        return section.minimumLineSpacing
    }
    
    func minimumInteritemSpacingForSection(at index: Int) -> CGFloat {
        guard let section = currentSections[safe: index] else { return .zero }
        return section.minimumInteritemSpacing
    }
}
