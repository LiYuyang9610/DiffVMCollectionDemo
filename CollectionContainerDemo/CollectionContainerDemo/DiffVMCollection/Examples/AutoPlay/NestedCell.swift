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
            make.leading.equalToSuperview().inset(200)
            make.top.equalToSuperview()
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
    
    func preferredSize(for viewModel: NestedCellViewModel, within containerSize: CGSize) -> CGSize {
        CGSize(width: containerSize.width, height: viewModel.itemHeight)
    }
    
    func bind(to viewModel: NestedCellViewModel) {
        collectionContainer.viewModel.parentViewModel = viewModel
        viewModel.setupCollectionViewModel(with: collectionContainer.viewModel)
        
        viewModel.getService(for: AutoPlayService.self)?.visibleItemsGetter = { [weak self] in
            guard let self else { return [] }
            return videoCollectionView.visibleCells.compactMap { cell in
                guard let indexPath = self.videoCollectionView.indexPath(for: cell) else { return nil }
                return AutoPlayVisibleItemInfo(indexPath: IndexPathWrapper(indexPath), frame: CGRectWrapper(cell.frame))
            }
        }
        viewModel.getService(for: AutoPlayService.self)?.playingItemShouldChange.sink { [weak viewModel] playItemsInfo in
            if let previousInfo = playItemsInfo.previousInfo {
                viewModel?.notifyChildren(for: VideoCellHandler.self) { $0.stop(at: previousInfo.indexPath) }
            }
            if let currentInfo = playItemsInfo.currentInfo {
                viewModel?.notifyChildren(for: VideoCellHandler.self) { $0.play(at: currentInfo.indexPath) }
            }
        }.store(in: &cancellables)

        videoCollectionView.publisher(for: \.contentOffset).sink { [weak self] contentOffset in
            guard let self else { return }
            guard let indexPath = viewModel.findParentValue(for: AutoPlayCollectionHandler.self, { $0.currentIndexPath(for: viewModel) }) else { return }
            if viewModel.currentPlaying {
                let horizontalOffset = contentOffset.x
                let verticalOffset = contentOffset.y
                let actualContentOffset = CGSizeWrapper(width: horizontalOffset + videoCollectionView.contentInset.left + videoCollectionView.adjustedContentInset.left, height: verticalOffset + videoCollectionView.contentInset.top + videoCollectionView.adjustedContentInset.top)
                viewModel.getService(for: AutoPlayService.self)?.contentScrolling(to: actualContentOffset)
            } else {
                viewModel.parentViewModel?.getService(for: AutoPlayService.self)?.manuallyPlayItem(at: indexPath)
            }
        }.store(in: &cancellables)
        
        let smallVideoItemSpacing: CGFloat = 5
        let items = (0..<10).map { _ in
            AnyDiffVMItem(cellType: VideoCell.self, cellViewModel: VideoCellViewModel(style: .small, itemSpacing: smallVideoItemSpacing))
        }
        let section = DiffVMSection(title: "videos", items: items, minimumLineSpacing: smallVideoItemSpacing)
        
        collectionContainer.apply([section], animated: true, completion: nil)
    }
}
