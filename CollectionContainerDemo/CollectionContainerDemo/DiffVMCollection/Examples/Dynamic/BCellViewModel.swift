//
//  BCellViewModel.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation
import Combine

class BViewModel: DiffViewModelNode {
    
    static func == (lhs: BViewModel, rhs: BViewModel) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    struct Model {
        let text: String
        init(jsonNode: JSONNode) {
            self.text = jsonNode["string_value"].stringValue
        }
    }
    
    weak var parentViewModel: ViewModelNode?
    
    let currentSelectingState: CurrentValueSubject<Bool, Never> = .init(false)
    
    let model: Model
    
    let uuid: UUID = UUID()
    
    let servicesContainer: ServicesContainer = .init()
        
    required init(jsonNode: JSONNode) {
        self.model = Model(jsonNode: jsonNode)
    }
    
    func transform() {
        
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}

extension BViewModel: ItemInfoHandler {
    var itemId: AnyHashable { self }
    
    var selecting: Bool { currentSelectingState.value }
    
    func select() {
        currentSelectingState.send(true)
    }
    
    func unselect() {
        currentSelectingState.send(false)
    }
}
