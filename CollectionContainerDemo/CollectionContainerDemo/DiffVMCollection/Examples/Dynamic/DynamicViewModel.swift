//
//  DynamicViewModel.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation

class DynamicViewModel: ViewModelNode {
    let servicesContainer: ServicesContainer = .init()
    
    weak var parentViewModel: (any ViewModelNode)?
    
    var childrenViewModels: [any ViewModelNode] {
        [collectionViewModel]
    }
    
    private let collectionViewModel: DiffVMCollectionViewModel
    
    init(collectionViewModel: DiffVMCollectionViewModel) {
        self.collectionViewModel = collectionViewModel
        collectionViewModel.parentViewModel = self
    }
    
    func transform() {
        
    }
}

extension DynamicViewModel: DiffVMEventHandler {
    func selectItem(at indexPath: IndexPath, with itemId: AnyHashable) {
        guard let toBeSelectedCellViewModel = findChildrenValue(for: ItemInfoHandler.self, { cellViewModel in
            cellViewModel.itemId == itemId ? cellViewModel : nil
        }) else { return }
        notifyChildren(for: ItemInfoHandler.self) { cellViewModel in
            if cellViewModel === toBeSelectedCellViewModel {
                cellViewModel.select()
            } else {
                cellViewModel.unselect()
            }
        }
    }
}

protocol ItemInfoHandler: AnyObject {
    var itemId: AnyHashable { get }
    var selecting: Bool { get }
    func select()
    func unselect()
}
