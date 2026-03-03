//
//  VideoCellView.swift
//  CollectionContainerDemo
//
//  Created by ByteDance on 3/3/26.
//

import Foundation
import SwiftUI

private struct VideoCellViewModelKey: EnvironmentKey {
    static let defaultValue = VideoCellViewModel(style: .normal, itemSpacing: 10, canBePlayed: true)
}

private extension EnvironmentValues {
  var videoCellViewModel: VideoCellViewModel {
    get { self[VideoCellViewModelKey.self] }
    set { self[VideoCellViewModelKey.self] = newValue }
  }
}

private struct VideoCellView: UIViewRepresentable {
    
    let videoCell: VideoCell
    @Environment(\.videoCellViewModel) var viewModel
    
    init(videoCell: VideoCell) {
        self.videoCell = videoCell
    }
    
    func makeCoordinator() -> VideoCellViewModel {
        viewModel
    }
    
    func makeUIView(context: Context) -> VideoCell {
        videoCell.bind(to: context.coordinator)
        return videoCell
    }
    
    func updateUIView(_ uiView: VideoCell, context: Context) {
        uiView.bind(to: context.coordinator)
    }
}

private struct SelectTraits: PreviewModifier {
    func body(content: Content, context: VideoCellViewModel) -> some View {
        content
            .environment(\.videoCellViewModel, context)
    }
    
    static func makeSharedContext() async throws -> VideoCellViewModel {
        let viewModel = VideoCellViewModel(style: .normal, itemSpacing: 10, canBePlayed: true)
        viewModel.parentViewModel = MockedViewModel()
        viewModel.select()
        return viewModel
    }
}

private extension PreviewTrait<Preview.ViewTraits> {
    static var sampleCell: PreviewTrait {
        .modifier(SelectTraits())
    }
}


#Preview(traits: .sampleCell) {
    VideoCellView(videoCell: VideoCell(frame: .zero))
}

private class MockedViewModel: ViewModelNode {
    let servicesContainer: ServicesContainer = .init()
    
    var parentViewModel: (any ViewModelNode)?
    
    func transform() {
        
    }
}

extension MockedViewModel: AutoPlayCollectionHandler {
    func currentIndexPath<DiffVMType: ViewModelNode>(for itemViewModel: DiffVMType) -> IndexPathWrapper? {
        IndexPathWrapper(IndexPath(item: .zero, section: .zero))
    }
    
    func videoDidFinish<DiffVMType: ViewModelNode>(for itemViewModel: DiffVMType) {
        
    }
}
