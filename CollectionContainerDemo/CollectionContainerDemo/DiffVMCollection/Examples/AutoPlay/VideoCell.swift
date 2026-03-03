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
        label.minimumScaleFactor = 0.3
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    let selectingStateLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .center
        label.minimumScaleFactor = 0.3
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    let progressLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .center
        label.minimumScaleFactor = 0.3
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    private var cancellables = Set<AnyCancellable>()
    
    let player = DummyPlayer(totalProgress: 5)
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        contentView.addSubview(playingStateLabel)
        contentView.addSubview(selectingStateLabel)
        contentView.addSubview(progressLabel)
        playingStateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
        }
        selectingStateLabel.snp.makeConstraints { make in
            make.top.equalTo(playingStateLabel.snp.bottom)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
        }
        progressLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(selectingStateLabel.snp.bottom)
            make.width.lessThanOrEqualToSuperview()
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        player.pause()
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
        contentView.backgroundColor = viewModel.canBePlayed ? .green : .gray
        viewModel.currentSelectingState.sink { [weak self] selecting in
            guard let self else { return }
            selectingStateLabel.text = selecting ? "selecting" : ""
        }.store(in: &cancellables)
        viewModel.currentPlayingState.compactMap { [weak viewModel] playing in
            guard let viewModel else { return "" }
            guard let currentIndexPath = viewModel.currentIndexPath else { return "" }
            return "\(currentIndexPath.item)" + (playing ? "playing" : "paused")
        }.assign(to: \.text, on: playingStateLabel).store(in: &cancellables)
        viewModel.currentPlayingState.map { [canBePlayed = viewModel.canBePlayed] playing in
            guard canBePlayed else { return .gray }
            return playing ? UIColor.red : .green
        }.assign(to: \.backgroundColor, on: contentView).store(in: &cancellables)
        viewModel.currentPlayingState.sink { [weak self] playing in
            guard let self else { return }
            if playing {
                player.play()
            } else {
                player.pause()
            }
        }.store(in: &cancellables)
        player.currentProgress.map { progress in
            "progress: \(progress)"
        }.assign(to: \.text, on: progressLabel).store(in: &cancellables)
        player.completionEvent.sink { _ in
            viewModel.playerFinishPlay()
        }.store(in: &cancellables)
    }
}
