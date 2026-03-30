import SwiftUI

struct ContentView: View {
    @State private var buttonPressed = false
    
    var body: some View {
        VStack {
            Button(action: {
                buttonPressed.toggle()
            }) {
                Text(buttonPressed ? "Нажата!" : "Нажми меня")
                    .font(.title)
                    .padding()
                    .background(buttonPressed ? Color.green : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
