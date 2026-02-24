//
//  ContentView.swift
//  CollectionContainerDemo
//
//  Created by ByteDance on 2/24/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Dynamic Data", systemImage: "water.waves") {
                DynamicDataDemoView().ignoresSafeArea()
            }
            
            
            Tab("Auto Play", systemImage: "figure.seated.side.automatic") {
                AutoPlayDemoView().ignoresSafeArea()
            }
        }
    }
}

#Preview {
    ContentView()
}

struct DynamicDataDemoView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> DynamicViewController {
        DynamicViewController()
    }
    
    func updateUIViewController(_ uiViewController: DynamicViewController, context: Context) {}
}

struct AutoPlayDemoView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> AutoPlayViewController {
        AutoPlayViewController()
    }
    
    func updateUIViewController(_ uiViewController: AutoPlayViewController, context: Context) {}
}
