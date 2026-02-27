//
//  DiffVMCollectionViewModel.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation

/// Collection层级的view model, 接入方负责设置其parent view model
class DiffVMCollectionViewModel: ViewModelNode {
    weak var parentViewModel: ViewModelNode? = nil
    
    var childrenViewModels: [any ViewModelNode] = []
    
    let servicesContainer: ServicesContainer = .init()
    
    init() {
        
    }
    
    func transform() {
        
    }
    
    func indexPathForItem<DiffVMType: ViewModelNode>(of viewModel: DiffVMType) -> IndexPathWrapper? {
        findDirectChildrenValue(for: DiffVMSectionHandler.self) { sectionViewModel in
            guard let itemIndex = sectionViewModel.itemIndex(for: viewModel) else { return nil }
            guard let sectionIndex = childrenViewModels.firstIndex(where: { childViewModel in
                childViewModel === sectionViewModel
            }) else { return nil }
            return IndexPathWrapper(section: sectionIndex, item: itemIndex)
        }
    }
}
