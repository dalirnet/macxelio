import Foundation

class AppSettings: ObservableObject {
    @Published var socksPort: Int {
        didSet { UserDefaults.standard.set(socksPort, forKey: "socksPort") }
    }
    
    @Published var httpPort: Int {
        didSet { UserDefaults.standard.set(httpPort, forKey: "httpPort") }
    }
    
    @Published var autoConnect: Bool {
        didSet { UserDefaults.standard.set(autoConnect, forKey: "autoConnect") }
    }
    
    init() {
        self.socksPort = UserDefaults.standard.integer(forKey: "socksPort")
        if self.socksPort == 0 { self.socksPort = 10808 }
        
        self.httpPort = UserDefaults.standard.integer(forKey: "httpPort")
        if self.httpPort == 0 { self.httpPort = 10809 }
        
        self.autoConnect = UserDefaults.standard.bool(forKey: "autoConnect")
    }
}
