
import SwiftUI
import Combine

@Observable
class KeyboardLanguageManager {
    
    enum Language: String, Hashable, Identifiable, CaseIterable {
        case en = "en"
        case ja = "ja"
        
        var id: String {
            return self.rawValue
        }
    }
    
    static var shared = KeyboardLanguageManager()
    
    var language: Language = .en
    private init() { }
}

extension UIWindow {
    open override var textInputMode: UITextInputMode? {
        let language = KeyboardLanguageManager.shared.language.rawValue
        for inputMode in UITextInputMode.activeInputModes {
            if let inputModeLanguage = inputMode.primaryLanguage, inputModeLanguage.starts(with: language) {
                return inputMode
            }
        }
        // return nil or super.textInputMode to use the default ones
        return super.textInputMode
    }
}

extension Notification.Name {
    var publisher: NotificationCenter.Publisher {
        return NotificationCenter.default.publisher(for: self)
    }
}

struct ForceKeyboardDemo: View {
    @State private var manager = KeyboardLanguageManager.shared
    
    @FocusState private var focused
    @State private var cancellable: AnyCancellable?

    var body: some View {
        NavigationStack {
            VStack(spacing: 36) {
                Text("Keyboard with Controlled Language")
                    .font(.headline)

                
                HStack {
                    Text("Language Allowed")
                        .fontWeight(.semibold)
                    Spacer()
                    Picker(selection: $manager.language, content: {
                        ForEach(KeyboardLanguageManager.Language.allCases, content: {
                            Text($0.rawValue)
                                .tag($0)
                        })
                    }, label: {  })
                    
                }
                // hide the text field if the keyboard itself is not available
                if UITextInputMode.activeInputModes.contains(where: {$0.primaryLanguage?.starts(with: manager.language.rawValue) == true })  {
                    TextField("", text: .constant("test"))
                        .focused($focused)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.clear).stroke(.secondary, style: .init()))
                } else {
                    Text("Keyboard for \(manager.language.rawValue) not available.")
                }

            }
            .padding()
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.yellow.opacity(0.1))
            .navigationTitle("Force Keyboard Language")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                self.focused = false
            }
            .onChange(of: manager.language, initial: true, {
                let currentFocus = self.focused
                self.focused = false
                self.focused = currentFocus
            })
            .onAppear {
                self.cancellable = UITextInputMode.currentInputModeDidChangeNotification.publisher.receive(
                    on: DispatchQueue.main
                ).sink { notification in
                    self.focused = false
                    self.focused = true
                }
            }

        }
    }
}
