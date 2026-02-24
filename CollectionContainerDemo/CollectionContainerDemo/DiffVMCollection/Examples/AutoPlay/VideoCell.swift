//
//  VideoCell.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation
import UIKit
import Combine
import SnapKit

class VideoCell: UICollectionViewCell, DiffVMCellProtocol {
    
    static let reuseIdentifier: String = "VideoCell"
    
    let playingStateLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    let selectingStateLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private var cancellables = Set<AnyCancellable>()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        contentView.addSubview(playingStateLabel)
        contentView.addSubview(selectingStateLabel)
        playingStateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(100)
        }
        selectingStateLabel.snp.makeConstraints { make in
            make.top.equalTo(playingStateLabel.snp.bottom)
            make.centerX.equalToSuperview()
            make.width.equalTo(100)
        }
        contentView.backgroundColor = .green
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables = []
    }
    
    func preferredSize(for viewModel: VideoCellViewModel, within containerSize: CGSize) -> CGSize {
        switch viewModel.style {
        case .normal:
            CGSize(width: (containerSize.width - viewModel.itemSpacing) / CGFloat(viewModel.itemNumbersInRow), height: viewModel.itemHeight)
        case .small:
            CGSize(width: containerSize.width / CGFloat(viewModel.itemNumbersInRow), height: viewModel.itemHeight)
        }
    }
    
    func bind(to viewModel: VideoCellViewModel) {
        viewModel.currentSelectingState.sink { [weak self] selecting in
            guard let self else { return }
            selectingStateLabel.text = selecting ? "selecting" : ""
        }.store(in: &cancellables)
        viewModel.currentPlayingState.compactMap { [weak viewModel] playing in
            guard let viewModel else { return "" }
            guard let currentIndexPath = viewModel.currentIndexPath else { return "" }
            return "\(currentIndexPath.item)" + (playing ? "playing" : "paused")
        }.assign(to: \.text, on: playingStateLabel).store(in: &cancellables)
        viewModel.currentPlayingState.map { playing in
            playing ? UIColor.red : .green
        }.assign(to: \.backgroundColor, on: contentView).store(in: &cancellables)
    }
}
