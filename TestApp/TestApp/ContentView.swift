import SwiftUI

struct ContentView: View {
    @State private var showAlert = false
    
    var body: some View {
        VStack {
            Spacer()
            
            Button(action: {
                showAlert = true
            }) {
                Text("Тест")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 20)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .alert("Тест", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Кнопка работает!")
            }
            
            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
