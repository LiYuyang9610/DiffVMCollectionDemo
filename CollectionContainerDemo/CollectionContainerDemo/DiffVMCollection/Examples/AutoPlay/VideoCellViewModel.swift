//
//  VideoCellViewModel.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation
import Combine

class VideoCellViewModel: ViewModelNode, Hashable {
    
    enum CellOutlook {
        case normal
        case small
    }
    
    static func == (lhs: VideoCellViewModel, rhs: VideoCellViewModel) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    weak var parentViewModel: ViewModelNode?
    
    let uuid: UUID = UUID()
    
    let servicesContainer: ServicesContainer = .init()
    
    let currentSelectingState: CurrentValueSubject<Bool, Never> = .init(false)
    
    let currentPlayingState: CurrentValueSubject<Bool, Never> = .init(false)
    
    let style: CellOutlook
    
    let itemSpacing: CGFloat
    
    var itemNumbersInRow: Int {
        switch style {
        case .normal:
            2
        case .small:
            5
        }
    }
    
    var itemHeight: CGFloat {
        switch style {
        case .normal:
            250
        case .small:
            150
        }
    }
    
    var currentIndexPath: IndexPathWrapper? {
        findParentValue(for: AutoPlayCollectionHandler.self) { $0.currentIndexPath(for: self) }
    }
    
    init(style: CellOutlook, itemSpacing: CGFloat) {
        self.style = style
        self.itemSpacing = itemSpacing
    }
    
    func transform() {
        
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}

protocol VideoCellHandler: AnyObject {
    var itemId: AnyHashable { get }
    var selecting: Bool { get }
    func select()
    func unselect()
    func play(at indexPath: IndexPathWrapper)
    func stop(at indexPath: IndexPathWrapper)
}

extension VideoCellViewModel: VideoCellHandler {
    var itemId: AnyHashable { self }
    
    var selecting: Bool { currentSelectingState.value }
    
    func select() {
        currentSelectingState.send(true)
    }
    
    func unselect() {
        currentSelectingState.send(false)
    }
    
    func play(at indexPath: IndexPathWrapper) {
        guard indexPath == currentIndexPath else { return }
        currentPlayingState.send(true)
    }
    
    func stop(at indexPath: IndexPathWrapper) {
        guard indexPath == currentIndexPath else { return }
        currentPlayingState.send(false)
    }
}
