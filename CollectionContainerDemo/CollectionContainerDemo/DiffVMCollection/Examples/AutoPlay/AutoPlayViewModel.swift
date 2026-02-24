//
//  AutoPlayViewModel.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation

class AutoPlayViewModel: ViewModelNode {
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

extension AutoPlayViewModel: DiffVMEventHandler {
    func selectItem(at indexPath: IndexPath, with itemId: AnyHashable) {
        notifyChildren(for: VideoCellHandler.self) { cellViewModel in
            if cellViewModel.itemId == itemId {
                cellViewModel.select()
            } else {
                cellViewModel.unselect()
            }
        }
    }
}

protocol AutoPlayCollectionHandler {
    func currentIndexPath<DiffVMType: ViewModelNode & Hashable>(for itemViewModel: DiffVMType) -> IndexPathWrapper?
}

extension AutoPlayViewModel: AutoPlayCollectionHandler {
    func currentIndexPath<DiffVMType: ViewModelNode & Hashable>(for itemViewModel: DiffVMType) -> IndexPathWrapper? {
        collectionViewModel.indexPathForItem(of: itemViewModel)
    }
}
