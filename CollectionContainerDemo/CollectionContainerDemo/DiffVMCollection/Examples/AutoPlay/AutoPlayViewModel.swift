//
//  AutoPlayViewModel.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation
import Combine

class AutoPlayViewModel: ViewModelNode {
    let servicesContainer: ServicesContainer = .init()
    
    weak var parentViewModel: (any ViewModelNode)?
    
    var childrenViewModels: [any ViewModelNode] {
        [collectionViewModel]
    }
    
    private let collectionViewModel: DiffVMCollectionViewModel
    
    private let videoFinishEvent: PassthroughSubject<IndexPathWrapper, Never> = .init()
    
    var videoFinish: AnyPublisher<IndexPathWrapper, Never> {
        videoFinishEvent.eraseToAnyPublisher()
    }
    
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
    func videoDidFinish<DiffVMType: ViewModelNode & Hashable>(for itemViewModel: DiffVMType)
}

extension AutoPlayViewModel: AutoPlayCollectionHandler {
    func currentIndexPath<DiffVMType: ViewModelNode & Hashable>(for itemViewModel: DiffVMType) -> IndexPathWrapper? {
        collectionViewModel.indexPathForItem(of: itemViewModel)
    }
    
    func videoDidFinish<DiffVMType: ViewModelNode & Hashable>(for itemViewModel: DiffVMType) {
        guard let indexPath = collectionViewModel.indexPathForItem(of: itemViewModel) else { return }
        videoFinishEvent.send(indexPath)
    }
}
