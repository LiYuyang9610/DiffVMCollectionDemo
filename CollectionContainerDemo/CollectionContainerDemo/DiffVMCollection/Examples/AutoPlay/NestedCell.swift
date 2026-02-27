//
//  NestedCell.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/23/26.
//

import Foundation
import UIKit
import Combine
import SnapKit

class NestedCell: UICollectionViewCell, DiffVMCellProtocol {
    
    static let reuseIdentifier: String = "NestedCell"
    
    let flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        return layout
    }()
    
    let triggerLine: UIView = {
        let line = UIView()
        line.backgroundColor = .orange
        return line
    }()
    
    let collectionContainer: DiffVMCollectionContainer<UICollectionViewFlowLayout, VideoCell>
    
    private var videoCollectionView: UICollectionView {
        collectionContainer.collectionView
    }

    private var cancellables = Set<AnyCancellable>()
    
    override init(frame: CGRect) {
        collectionContainer = DiffVMCollectionContainer(flowLayout, cellTypes: VideoCell.self)
        super.init(frame: .zero)
        contentView.addSubview(collectionContainer.collectionView)
        collectionContainer.collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.addSubview(triggerLine)
        triggerLine.snp.makeConstraints { make in
            make.height.equalToSuperview().dividedBy(2)
            make.width.equalTo(3)
            make.centerX.top.equalToSuperview()
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables = []
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let inset = UIEdgeInsets(top: .zero, left: bounds.width / 2, bottom: .zero, right: bounds.width / 2)
        collectionContainer.collectionView.contentInset = inset
    }
    
    func preferredSize(for viewModel: NestedCellViewModel, within containerSize: CGSize) -> CGSize {
        CGSize(width: containerSize.width, height: viewModel.itemHeight)
    }
    
    func bind(to viewModel: NestedCellViewModel) {
        collectionContainer.viewModel.parentViewModel = viewModel
        viewModel.setupCollectionViewModel(with: collectionContainer.viewModel)
        
        viewModel.getService(for: AutoPlayService.self)?.visibleItemsGetter = { [weak self, weak viewModel] in
            guard let self, let viewModel else { return [] }
            let canBePlayedInfo = viewModel.collectChildrenKeyedValues(for: VideoCellHandler.self) { (child) -> (IndexPathWrapper, Bool)? in
                guard let childViewModel = child as? ViewModelNode & VideoCellHandler else { return nil }
                guard let indexPath = viewModel.currentIndexPath(for: childViewModel) else { return nil }
                return (indexPath, childViewModel.canBePlayed)
            }
            return videoCollectionView.visibleCells.compactMap { cell in
                guard let indexPath = self.videoCollectionView.indexPath(for: cell) else { return nil }
                let canBePlayed = canBePlayedInfo[IndexPathWrapper(indexPath)] ?? false
                return AutoPlayVisibleItemInfo(indexPath: IndexPathWrapper(indexPath), frame: CGRectWrapper(cell.frame), canBePlayed: canBePlayed)
            }
        }
        viewModel.getService(for: AutoPlayService.self)?.containerSizeGetter = { [weak self] in
            guard let self else { return .zero }
            return CGSizeWrapper(videoCollectionView.bounds.size)
        }
        viewModel.getService(for: AutoPlayService.self)?.playingItemShouldChange.sink { [weak viewModel] playItemsInfo in
            if let previousInfo = playItemsInfo.previousInfo {
                viewModel?.notifyChildren(for: VideoCellHandler.self) { $0.stop(at: previousInfo.indexPath) }
            }
            if let currentInfo = playItemsInfo.currentInfo {
                viewModel?.notifyChildren(for: VideoCellHandler.self) { $0.play(at: currentInfo.indexPath) }
            }
        }.store(in: &cancellables)
        
        viewModel.videoFinish.sink { [weak viewModel] indexPath in
            guard let viewModel else { return }
            viewModel.getService(for: AutoPlayService.self)?.manuallyPlayItem(at: indexPath)
        }.store(in: &cancellables)

        // notice this dropFirst() here
        // when outside collection scrolling, and this nested cell runs into bind(to:)
        // the publisher for contentOffset will be triggered automatically
        // this is not caused by user interaction and should be ignored
        videoCollectionView.publisher(for: \.contentOffset).dropFirst().sink { [weak self] contentOffset in
            guard let self else { return }
            guard let indexPath = viewModel.findParentValue(for: AutoPlayCollectionHandler.self, { $0.currentIndexPath(for: viewModel) }) else { return }
            if viewModel.currentPlaying {
                let horizontalOffset = contentOffset.x
                let verticalOffset = contentOffset.y
                let actualContentOffset = CGSizeWrapper(width: horizontalOffset, height: verticalOffset + videoCollectionView.contentInset.top + videoCollectionView.adjustedContentInset.top)
                viewModel.getService(for: AutoPlayService.self)?.contentScrolling(to: actualContentOffset)
            } else {
                viewModel.parentViewModel?.getService(for: AutoPlayService.self)?.manuallyPlayItem(at: indexPath)
            }
        }.store(in: &cancellables)
        
        let smallVideoItemSpacing: CGFloat = 5
        let items = (0..<10).map { index in
            AnyDiffVMItem(cellType: VideoCell.self, cellViewModel: VideoCellViewModel(style: .small, itemSpacing: smallVideoItemSpacing, canBePlayed: index % 3 == 0))
        }
        let section = DiffVMSection(title: "videos", items: items, minimumLineSpacing: smallVideoItemSpacing)
        
        collectionContainer.apply([section], animated: true, completion: nil)
    }
}
