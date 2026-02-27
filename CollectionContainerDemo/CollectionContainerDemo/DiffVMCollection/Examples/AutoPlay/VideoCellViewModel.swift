//
//  VideoCellViewModel.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation
import Combine

/// A View Model representing an individual video cell within a collection.
/// It manages the state for selection and playback, and adapts its layout metrics based on its style.
class VideoCellViewModel: ViewModelNode, Hashable {
    
    /// Defines the visual presentation style of the video cell.
    enum CellOutlook {
        /// A standard, larger cell style.
        case normal
        /// A compact, smaller cell style.
        case small
    }
    
    static func == (lhs: VideoCellViewModel, rhs: VideoCellViewModel) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    /// The parent view model in the view model tree architecture.
    weak var parentViewModel: ViewModelNode?
    
    /// A unique identifier for this cell instance.
    let uuid: UUID = UUID()
    
    /// A container for dependency injection and service location specific to this node.
    let servicesContainer: ServicesContainer = .init()
    
    /// A reactive publisher representing whether the cell is currently selected.
    let currentSelectingState: CurrentValueSubject<Bool, Never> = .init(false)
    
    /// A reactive publisher representing whether the video in the cell is currently playing.
    let currentPlayingState: CurrentValueSubject<Bool, Never> = .init(false)
    
    /// The visual presentation style of the cell.
    let style: CellOutlook
    
    /// The spacing to apply around the cell.
    let itemSpacing: CGFloat
    
    let canBePlayed: Bool
    
    /// The number of items that should appear in a single row, determined by the cell's style.
    var itemNumbersInRow: Int {
        switch style {
        case .normal:
            2
        case .small:
            5
        }
    }
    
    /// The fixed height of the cell, determined by the cell's style.
    var itemHeight: CGFloat {
        switch style {
        case .normal:
            250
        case .small:
            150
        }
    }
    
    /// Dynamically resolves the cell's current index path by traversing up the view model tree
    /// and querying an `AutoPlayCollectionHandler` parent.
    var currentIndexPath: IndexPathWrapper? {
        findParentValue(for: AutoPlayCollectionHandler.self) { $0.currentIndexPath(for: self) }
    }
    
    /// Initializes a new video cell view model.
    /// - Parameters:
    ///   - style: The visual presentation style of the cell.
    ///   - itemSpacing: The spacing to apply around the item.
    init(style: CellOutlook, itemSpacing: CGFloat, canBePlayed: Bool) {
        self.style = style
        self.itemSpacing = itemSpacing
        self.canBePlayed = canBePlayed
    }
    
    /// Performs any necessary transformations or setup for the view model.
    func transform() {
        
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    func playerFinishPlay() {
        notifyParent(for: AutoPlayCollectionHandler.self) { $0.videoDidFinish(for: self) }
    }
}

/// A protocol defining the core interactive operations and state available for a video cell.
protocol VideoCellHandler: AnyObject {
    /// A unique hashable identifier for the item.
    var itemId: AnyHashable { get }
    /// A boolean indicating whether the cell is currently selected.
    var selecting: Bool { get }
    
    var canBePlayed: Bool { get }
    
    /// Marks the cell as selected.
    func select()
    
    /// Marks the cell as unselected.
    func unselect()
    
    /// Requests the cell to begin playing its video if the provided index path matches its current position.
    /// - Parameter indexPath: The index path where playback is being requested.
    func play(at indexPath: IndexPathWrapper)
    
    /// Requests the cell to stop playing its video if the provided index path matches its current position.
    /// - Parameter indexPath: The index path where playback should be stopped.
    func stop(at indexPath: IndexPathWrapper)
}

// MARK: - VideoCellHandler Conformance

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
