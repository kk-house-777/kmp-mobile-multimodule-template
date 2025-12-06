import SwiftUI
import Feature_a

struct ContentView: View {
    @State private var showContent = false
    var body: some View {
        FeatureAView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
