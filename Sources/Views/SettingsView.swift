import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = AppSettings()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Content
            Form {
                Section("Proxy Ports") {
                    HStack {
                        Text("SOCKS Port")
                        Spacer()
                        TextField("", value: $settings.socksPort, format: .number)
                            .frame(width: 80)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text("HTTP Port")
                        Spacer()
                        TextField("", value: $settings.httpPort, format: .number)
                            .frame(width: 80)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                Section("General") {
                    Toggle("Auto-connect on launch", isOn: $settings.autoConnect)
                }
            }
            .formStyle(.grouped)
            .padding()
        }
        .frame(width: 350, height: 300)
    }
}
