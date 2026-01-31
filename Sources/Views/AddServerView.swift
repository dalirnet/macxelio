import SwiftUI

struct AddServerView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var address = ""
    @State private var port = 443
    @State private var protocolType: Server.ProtocolType = .vless
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Server")
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
                Section("Server Info") {
                    TextField("Name", text: $name)
                    TextField("Address", text: $address)
                    
                    HStack {
                        Text("Port")
                        Spacer()
                        TextField("", value: $port, format: .number)
                            .frame(width: 80)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Picker("Protocol", selection: $protocolType) {
                        ForEach(Server.ProtocolType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .padding()
            
            // Footer
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Add Server") {
                    // TODO: Save server
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || address.isEmpty)
            }
            .padding()
        }
        .frame(width: 350, height: 350)
    }
}
