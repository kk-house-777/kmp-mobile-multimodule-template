//
// Created by kk__777 on 2025/12/06.
//

import SwiftUI

public struct FeatureBView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            Text("Feature B")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("This is Feature B module")
                .font(.body)

            Text("No KMP dependency")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

#Preview {
    FeatureBView()
}
