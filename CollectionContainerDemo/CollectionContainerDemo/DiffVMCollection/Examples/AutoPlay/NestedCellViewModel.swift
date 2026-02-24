//
//  NestedCellViewModel.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/23/26.
//

import Foundation
import Combine

class NestedCellViewModel: ViewModelNode, Hashable {
    
    static func == (lhs: NestedCellViewModel, rhs: NestedCellViewModel) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    weak var parentViewModel: ViewModelNode?
    
    var childrenViewModels: [any ViewModelNode] {
        collectionViewModel.map { [$0] } ?? []
    }
    
    let itemHeight: CGFloat
    
    let uuid: UUID = UUID()
    
    let servicesContainer: ServicesContainer = .init()
    
    private var collectionViewModel: DiffVMCollectionViewModel?
    
    private(set) var currentPlaying: Bool = false
    
    var currentIndexPath: IndexPathWrapper? {
        findParentValue(for: AutoPlayCollectionHandler.self) { $0.currentIndexPath(for: self) }
    }
    
    init(itemHeight: CGFloat) {
        self.itemHeight = itemHeight
    }
    
    func transform() {
        
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    func setupCollectionViewModel(with collectionViewModel: DiffVMCollectionViewModel) {
        self.collectionViewModel = collectionViewModel
    }
}

extension NestedCellViewModel: VideoCellHandler {
    var itemId: AnyHashable { self }
    
    var selecting: Bool { false }
    
    func select() {
        
    }
    
    func unselect() {
        
    }
    
    func play(at indexPath: IndexPathWrapper) {
        guard indexPath == currentIndexPath else { return }
        currentPlaying = true
        guard let autoPlayService = getService(for: AutoPlayService.self) else { return }
        autoPlayService.manuallyPlayItem(at: autoPlayService.playingInfo.previousInfo?.indexPath)
    }
    
    func stop(at indexPath: IndexPathWrapper) {
        guard indexPath == currentIndexPath else { return }
        currentPlaying = false
        getService(for: AutoPlayService.self)?.manuallyPlayItem(at: nil)
    }
}

extension NestedCellViewModel: AutoPlayCollectionHandler {
    func currentIndexPath<DiffVMType: ViewModelNode & Hashable>(for itemViewModel: DiffVMType) -> IndexPathWrapper? {
        collectionViewModel?.indexPathForItem(of: itemViewModel)
    }
}
