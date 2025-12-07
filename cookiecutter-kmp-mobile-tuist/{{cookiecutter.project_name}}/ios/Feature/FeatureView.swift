//
// Created by kk__777 on 2025/12/06.
//

import SwiftUI
import KMPFramework

public struct FeatureView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            Text("Feature")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("kmp : \(FeatureScreen())")
                .font(.caption)
                .foregroundColor(.blue)
        }
    }
}
