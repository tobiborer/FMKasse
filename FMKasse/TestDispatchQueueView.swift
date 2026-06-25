
import Foundation
import SwiftUI

struct TestDispatchQueueView: View {
    var body: some View {
        Button("Test") {
            DispatchQueue.main.async {
                print("Hallo aus DispatchQueue!")
            }
        }
    }
}

struct TestDispatchQueueView_Previews: PreviewProvider {
    static var previews: some View {
        TestDispatchQueueView()
    }
}
