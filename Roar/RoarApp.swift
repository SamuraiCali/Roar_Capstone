import SwiftUI
import Amplify
import AWSCognitoAuthPlugin
import AWSAPIPlugin
import AWSS3StoragePlugin

@main
struct RoarApp: App {
    
    init() {
        configureAmplify()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    func configureAmplify() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin())
            
            // Check for Config File BEFORE configuring
            guard let configUrl = Bundle.main.url(forResource: "amplify_outputs", withExtension: "json") else {
                fatalError("CRITICAL ERROR: `amplify_outputs.json` was NOT found in the Bundle.\nSOLUTION: Click `amplify_outputs.json` in Xcode Project Navigator -> Enable 'Target Membership' for 'Roar' in the Inspector (Right sidebar).")
            }
            print("Found configuration at: \(configUrl)")
            
            // DEBUG: Read content to ensure it's valid
            let data = try Data(contentsOf: configUrl)
            if let content = String(data: data, encoding: .utf8) {
                print("--- CONFIG CONTENT START ---")
                print(content)
                print("--- CONFIG CONTENT END ---")
            } else {
                print("CRITICAL: Config file exists but is not readable as UTF-8.")
            }
            
            try Amplify.configure(with: .amplifyOutputs)
            print("Amplify configured successfully")
        } catch {
            print("Could not configure Amplify: \(error)")
             // Crash immediately so we see the real error
            fatalError("Amplify failed to configure: \(error)")
        }
    }
}
