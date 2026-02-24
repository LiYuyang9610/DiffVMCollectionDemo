//
//  ACell.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation
import UIKit
import Combine
import SnapKit

class ACell: UICollectionViewCell, DiffVMCellProtocol {
    
    static let reuseIdentifier: String = "A.Cell"
    
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
    
    func preferredSize(for viewModel: AViewModel, within containerSize: CGSize) -> CGSize {
        CGSize(width: containerSize.width, height: 200)
    }
    
    func bind(to viewModel: AViewModel) {
        titleLabel.text = "\(viewModel.model.number)"
        viewModel.currentSelectingState.sink { [weak self] selecting in
            guard let self else { return }
            if selecting {
                contentView.backgroundColor = .red
            } else {
                contentView.backgroundColor = .green
            }
        }.store(in: &cancellables)
    }
}
