import SwiftUI

struct ActionTile: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title2)
                Text(title)
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(color)
            .cornerRadius(14)
            .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
