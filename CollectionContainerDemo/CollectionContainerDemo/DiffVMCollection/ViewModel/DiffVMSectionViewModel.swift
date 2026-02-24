//
//  DiffVMSectionViewModel.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation

/// Section层级的view model, 接入方不感知
class DiffVMSectionViewModel: ViewModelNode {
    weak var parentViewModel: ViewModelNode? = nil
    
    var childrenViewModels: [any ViewModelNode]
    
    let servicesContainer: ServicesContainer = .init()
    
    init(_ childrenViewModels: [any ViewModelNode]) {
        self.childrenViewModels = childrenViewModels
        childrenViewModels.forEach { cellViewModel in
            cellViewModel.parentViewModel = self
        }
    }
    
    func transform() {
        
    }
}

extension DiffVMSectionViewModel: DiffVMSectionHandler {
    func itemIndex(for itemViewModel: any ViewModelNode) -> Int? {
        childrenViewModels.firstIndex { cellViewModel in
            cellViewModel === itemViewModel
        }
    }
}
