//
//  BCell.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation
import UIKit
import Combine
import SnapKit

class BCell: UICollectionViewCell, DiffVMCellProtocol {
    
    static let reuseIdentifier: String = "B.Cell"
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .cyan
        return label
    }()
    
    private var cancellables = Set<AnyCancellable>()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(50)
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
    
    func preferredSize(for viewModel: BViewModel, within containerSize: CGSize) -> CGSize {
        CGSize(width: containerSize.width, height: 100)
    }
    
    func bind(to viewModel: BViewModel) {
        titleLabel.text = viewModel.model.text
        viewModel.currentSelectingState.sink { [weak self] selecting in
            guard let self else { return }
            if selecting {
                contentView.backgroundColor = .orange
            } else {
                contentView.backgroundColor = .cyan
            }
        }.store(in: &cancellables)
    }
}
