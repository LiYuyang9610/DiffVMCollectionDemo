//
//  DynamicViewController.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/11/26.
//

import Foundation
import UIKit
import SnapKit
import Combine

class DynamicViewController: UIViewController {
    
    let collectionContainer: DiffVMCollectionContainer<UICollectionViewFlowLayout, ACell, BCell>
    
    private var videoCollectionView: UICollectionView {
        collectionContainer.collectionView
    }
    
    let itemFactory: DiffItemFactory = DiffItemFactory()
    
    let flowLayout = UICollectionViewFlowLayout()
    
    let viewModel: DynamicViewModel
    
    init() {
        collectionContainer = DiffVMCollectionContainer(flowLayout, cellTypes: ACell.self, BCell.self)
        viewModel = DynamicViewModel(collectionViewModel: collectionContainer.viewModel)
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.transform()
        view.addSubview(videoCollectionView)
        videoCollectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        itemFactory.register(for: ACell.self) { jsonNode in
            jsonNode["type"].intValue == 1
        }
        
        itemFactory.register(for: BCell.self) { jsonNode in
            jsonNode["type"].intValue == 2
        }
        let jsonArrayList: JSONNode = .array([
            .object([
                ("type", .number(1)),
                ("number_value", .number(10))
            ]),
            .object([
                ("type", .number(2)),
                ("string_value", .string("string"))
            ])
        ])
        let items = jsonArrayList.arrayValue.compactMap { jsonNode in
            itemFactory.makeItem(from: jsonNode)
        }
        let section = DiffVMSection(title: "section1", items: items)
        collectionContainer.apply([section], animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            let updatedJsonArrayList: JSONNode = .array([
                .object([
                    ("type", .number(1)),
                    ("number_value", .number(10))
                ]),
                .object([
                    ("type", .number(2)),
                    ("string_value", .string("string"))
                ]),
                .object([
                    ("type", .number(1)),
                    ("number_value", .number(10))
                ]),
            ])
            let updatedItems = updatedJsonArrayList.arrayValue.compactMap { jsonNode in
                self.itemFactory.makeItem(from: jsonNode)
            }
            let updatedSection = DiffVMSection(title: "section2", items: updatedItems)
            self.collectionContainer.apply([section, updatedSection], animated: true, completion: nil)
        }
    }
}
