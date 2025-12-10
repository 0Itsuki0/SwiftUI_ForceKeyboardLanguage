// MARK: Each Keyboard With its Own Language
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
        
        var displayTitle: String {
            switch self {
            case .en:
                "English"
            case .ja:
                "Japanese"
            }
        }
    }
    
    static var shared = KeyboardLanguageManager()
    
    var language: Language? = nil
    
    private init() {}
}

extension UIWindow {
    
    open override var textInputMode: UITextInputMode? {
        guard let language = KeyboardLanguageManager.shared.language?.rawValue else {
            return nil
        }
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
    @FocusState private var focusedField: KeyboardLanguageManager.Language?
    @State private var tempDismiss = false
    @State private var cancellable: AnyCancellable?
    
    @State private var selectedLanguage: KeyboardLanguageManager.Language = .en
    var body: some View {
        NavigationStack {
            VStack(spacing: 36) {

                Text("Language Per TextField")
                    .font(.headline)
                ForEach(KeyboardLanguageManager.Language.allCases) { language in
                    if UITextInputMode.activeInputModes.contains(where: {$0.primaryLanguage?.starts(with: language.rawValue) == true}) {
                        
                        TextField("", text: .constant(language.displayTitle))
                            .focused($focusedField, equals: language)
                            // Following will not work because a disabled text field can never become focused
                            // .disabled(focusedField != language)
                            .disabled(manager.language != language)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 8).fill(.clear).stroke(.secondary, style: .init()))
                            .contentShape(.rect)
                            .onTapGesture {
                                if self.manager.language != language {
                                    self.manager.language = language
                                }
                            }

                    } else {
                        Text("Keyboard for \(language.displayTitle) is not available.")
                    }
                    
                }
                
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.yellow.opacity(0.1))
            .navigationTitle("Force Keyboard Language")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                self.manager.language = nil
            }
            .onChange(of: manager.language, initial: true, {
                if manager.language != self.focusedField {
                    self.focusedField = manager.language
                }
            })
            .onChange(of: self.focusedField, {
                // handle dismiss due to, for example, user taps on the return button , only
                if self.focusedField == nil, tempDismiss == false {
                    self.manager.language = nil
                }
            })
            .onAppear {
                self.cancellable = UITextInputMode.currentInputModeDidChangeNotification.publisher.receive(
                    on: DispatchQueue.main
                ).sink { notification in
                    self.tempDismiss = true
                    
                    let current = self.focusedField
                    self.focusedField = nil
                    self.focusedField = current
                    
                    self.tempDismiss = false

                }
            }
        }
    }
}
