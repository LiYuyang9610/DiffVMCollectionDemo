//
//  DiffItemFactory.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation

protocol DiffViewModelNode: ViewModelNode & Hashable {
    init(jsonNode: JSONNode)
}

class DiffItemFactory {
    private var builders: [(JSONNode) -> AnyDiffVMItem?] = []
    
    func register<CellType: DiffVMCellProtocol>(for cellType: CellType.Type, while condition: @escaping (JSONNode) -> Bool) where CellType.ViewModelType: DiffViewModelNode {
        let builder: (JSONNode) -> AnyDiffVMItem? = { jsonNode in
            guard condition(jsonNode) else { return nil }
            let viewModel = CellType.ViewModelType(jsonNode: jsonNode)
            return AnyDiffVMItem(cellType: CellType.self, cellViewModel: viewModel)
        }
        builders.append(builder)
    }
    
    func makeItem(from jsonNode: JSONNode) -> AnyDiffVMItem? {
        for builder in builders {
            guard let item = builder(jsonNode) else { continue }
            return item
        }
        return nil
    }
}
