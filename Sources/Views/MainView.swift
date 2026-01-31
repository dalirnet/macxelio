import SwiftUI

struct MainView: View {
    @State private var showSettings = false
    @State private var showAddServer = false
    @State private var showHelp = false
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("Macxelio")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Content
            VStack {
                Image(systemName: "network")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                
                Text("No servers configured")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Button("Add Server") {
                    showAddServer = true
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Spacer()
        }
        .frame(width: 400, height: 500)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showAddServer) {
            AddServerView()
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
            showSettings = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .addServer)) { _ in
            showAddServer = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .openHelp)) { _ in
            showHelp = true
        }
    }
}
