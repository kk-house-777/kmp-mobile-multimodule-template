import SwiftUI
import Feature

struct ContentView: View {
    @State private var showContent = false
    var body: some View {
        FeatureView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
