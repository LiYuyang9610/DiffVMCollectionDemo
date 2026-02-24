//
//  ACellViewModel.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation
import Combine

class AViewModel: DiffViewModelNode {
    static func == (lhs: AViewModel, rhs: AViewModel) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    struct Model {
        let number: Int
        init(jsonNode: JSONNode) {
            self.number = jsonNode["number_value"].intValue
        }
    }
    
    weak var parentViewModel: ViewModelNode?
    
    let uuid: UUID = UUID()
    
    let model: Model
    
    let servicesContainer: ServicesContainer = .init()
    
    let currentSelectingState: CurrentValueSubject<Bool, Never> = .init(false)
    
    required init(jsonNode: JSONNode) {
        self.model = Model(jsonNode: jsonNode)
    }
    
    func transform() {
        
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}

extension AViewModel: ItemInfoHandler {
    var itemId: AnyHashable { self }
    
    var selecting: Bool { currentSelectingState.value }
    
    func select() {
        currentSelectingState.send(true)
    }
    
    func unselect() {
        currentSelectingState.send(false)
    }
}
