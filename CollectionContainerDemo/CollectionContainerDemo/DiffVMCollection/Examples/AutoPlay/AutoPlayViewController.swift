//
//  AutoPlayViewController.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/6/26.
//

import Foundation
import UIKit
import SnapKit
import Combine

class AutoPlayViewController: UIViewController {
    
    let collectionContainer: DiffVMCollectionContainer<UICollectionViewFlowLayout, NestedCell, VideoCell>
    
    let viewModel: AutoPlayViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    private let flowLayout = UICollectionViewFlowLayout()
    
    private var videoCollectionView: UICollectionView {
        collectionContainer.collectionView
    }
    
    let forwardTriggerLine: UIView = {
        let line = UIView()
        line.backgroundColor = .orange
        return line
    }()
    
    let backwardTriggerLine: UIView = {
        let line = UIView()
        line.backgroundColor = .orange
        return line
    }()
    
    init() {
        collectionContainer = DiffVMCollectionContainer(flowLayout, cellTypes: NestedCell.self, VideoCell.self)
        viewModel = AutoPlayViewModel(collectionViewModel: collectionContainer.viewModel)
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.transform()
        let forwardTriggerLineLength: CGFloat = 250 + 10 + 150
        let backwardTriggerLineLength: CGFloat = 250 - 8 + 150
        let autoPlayService = AutoPlayServiceImpl(playRules: [
            ForwardScrollRule(triggerLineLength: forwardTriggerLineLength),
            BackwardScrollRule(triggerLineLength: backwardTriggerLineLength),
            EndRule()
        ])
        autoPlayService.visibleItemsGetter = { [weak self] in
            guard let self else { return [] }
            return videoCollectionView.visibleCells.compactMap { cell in
                guard let indexPath = self.videoCollectionView.indexPath(for: cell) else { return nil }
                return AutoPlayVisibleItemInfo(indexPath: IndexPathWrapper(indexPath), frame: CGRectWrapper(cell.frame))
            }
        }
        autoPlayService.playingItemShouldChange.sink { [weak self] playItemsInfo in
            guard let self else { return }
            if let previousInfo = playItemsInfo.previousInfo {
                viewModel.notifyChildren(for: VideoCellHandler.self) { $0.stop(at: previousInfo.indexPath) }
            }
            if let currentInfo = playItemsInfo.currentInfo {
                viewModel.notifyChildren(for: VideoCellHandler.self) { $0.play(at: currentInfo.indexPath) }
            }
        }.store(in: &cancellables)

        videoCollectionView.publisher(for: \.contentOffset).sink { [weak self] contentOffset in
            guard let self else { return }
            let verticalOffset = contentOffset.y
            // print(verticalOffset + videoCollectionView.contentInset.top + videoCollectionView.adjustedContentInset.top)
            let actualContentOffset = CGSizeWrapper(width: contentOffset.x, height: verticalOffset + videoCollectionView.contentInset.top + videoCollectionView.adjustedContentInset.top)
            autoPlayService.contentScrolling(to: actualContentOffset)
        }.store(in: &cancellables)
        viewModel.registerService(for: AutoPlayService.self, using: autoPlayService)
        view.addSubview(videoCollectionView)
        videoCollectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let sideTriggerLineLength: CGFloat = 200
        let nestedCellViewModel = NestedCellViewModel(itemHeight: 150)
        let horizontalAutoPlayService = AutoPlayServiceImpl(playRules: [
            LeftScrollRule(triggerLineLength: sideTriggerLineLength),
            RightScrollRule(triggerLineLength: sideTriggerLineLength),
            EndRule()
        ])
        nestedCellViewModel.registerService(for: AutoPlayService.self, using: horizontalAutoPlayService)
        let horizontalItem = AnyDiffVMItem(cellType: NestedCell.self, cellViewModel: nestedCellViewModel)
        let horizontalSection = DiffVMSection(title: "horizontal", items: [horizontalItem])
        
        let normalVideoItemSpacing: CGFloat = 10
        let items = (0..<20).map { _ in
            AnyDiffVMItem(cellType: VideoCell.self, cellViewModel: VideoCellViewModel(style: .normal, itemSpacing: normalVideoItemSpacing))
        }
        let section = DiffVMSection(title: "videos", items: items, minimumLineSpacing: 10, minimumInteritemSpacing: normalVideoItemSpacing)
        
        collectionContainer.apply([horizontalSection, section], animated: true, completion: nil)
        
        view.addSubview(forwardTriggerLine)
        forwardTriggerLine.snp.makeConstraints { make in
            make.height.equalTo(3)
            make.width.equalToSuperview().dividedBy(2)
            make.leading.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(forwardTriggerLineLength)
        }
        view.addSubview(backwardTriggerLine)
        backwardTriggerLine.snp.makeConstraints { make in
            make.height.equalTo(3)
            make.width.equalToSuperview().dividedBy(2)
            make.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(backwardTriggerLineLength)
        }
    }
}
