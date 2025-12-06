//
// Created by kk__777 on 2025/12/06.
//

import SwiftUI
import KMPFramework

public struct FeatureAView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            Text("Feature A")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("kmp Data-a: \(DataARepository())")
                .font(.caption)
                .foregroundColor(.blue)
        }
    }
}
