import SwiftUI

struct ContentView: View {
    @State private var showAlert = false
    @State private var showAlert2 = false
    @State private var showAlert3 = false
    
    var body: some View {
        VStack(spacing: 20) {
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
            
            Button(action: {
                showAlert2 = true
            }) {
                Text("Кнопка 2")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 20)
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .alert("Кнопка 2", isPresented: $showAlert2) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Вторая кнопка работает!")
            }
            
            Button(action: {
                showAlert3 = true
            }) {
                Text("Кнопка 3")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 20)
                    .background(Color.orange)
                    .cornerRadius(10)
            }
            .alert("Кнопка 3", isPresented: $showAlert3) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Третья кнопка работает!")
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
