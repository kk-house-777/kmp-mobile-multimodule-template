//
// Created by kk__777 on 2025/12/06.
//

import SwiftUI
import KMPFramework

public struct FeatureView: View {
    @State private var showContent = false
    
    public init() {}

    public var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Button(action: {
                    withAnimation {
                        showContent.toggle()
                    }
                }) {
                    Text("Click me!")
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                
                if showContent {
                    VStack(spacing: 20) {
                        Image(systemName: "swift")
                            .font(.system(size: 200))
                            .foregroundColor(.accentColor)
                        
                        Text("KMP: \(FeatureScreen())")
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
        }
    }
}
