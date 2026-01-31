import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Help")
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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Group {
                        Text("Getting Started")
                            .font(.headline)
                        
                        Text("Macxelio is a native macOS client for managing Xray proxy configurations.")
                            .foregroundColor(.secondary)
                    }
                    
                    Group {
                        Text("Keyboard Shortcuts")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ShortcutRow(key: "Cmd+N", description: "Add new server")
                            ShortcutRow(key: "Cmd+,", description: "Open settings")
                            ShortcutRow(key: "Cmd+?", description: "Show help")
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .frame(width: 350, height: 300)
    }
}

struct ShortcutRow: View {
    let key: String
    let description: String
    
    var body: some View {
        HStack {
            Text(key)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
            
            Text(description)
                .foregroundColor(.secondary)
        }
    }
}
