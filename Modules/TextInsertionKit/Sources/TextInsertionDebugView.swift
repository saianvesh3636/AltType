import SwiftUI

#if DEBUG
/// Debug view for configuring text insertion strategies
public struct TextInsertionDebugView: View {
    @ObservedObject var textInserter: UniversalTextInserter
    @State private var testText = "Test insertion text"
    
    public init(textInserter: UniversalTextInserter) {
        self.textInserter = textInserter
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Text Insertion Strategy Debug")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Strategy Order:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(textInserter.getCurrentStrategyOrder())
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Strategy Order:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Strategy Order", selection: $textInserter.debugStrategyOrder) {
                    ForEach(UniversalTextInserter.InsertionStrategyOrder.allCases, id: \.self) { order in
                        Text(order.rawValue)
                            .tag(order)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: textInserter.debugStrategyOrder) { _ in
                    // Strategy order will be saved automatically via didSet
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Test Insertion:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("Test text", text: $testText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Insert") {
                        textInserter.insertText(testText)
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if let result = textInserter.lastInsertionResult {
                    HStack {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.success ? .green : .red)
                        Text("Method: \(result.method)")
                            .font(.caption)
                        if let error = result.error {
                            Text("Error: \(error.localizedDescription)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(4)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Tips:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("• Changes are saved automatically")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("• Test with different applications")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("• Monitor console for debug logs")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

/// Menu bar item for quick strategy switching
public struct TextInsertionDebugMenuItem: View {
    @ObservedObject var textInserter: UniversalTextInserter
    
    public init(textInserter: UniversalTextInserter) {
        self.textInserter = textInserter
    }
    
    public var body: some View {
        Menu("Insertion Strategy") {
            ForEach(UniversalTextInserter.InsertionStrategyOrder.allCases, id: \.self) { order in
                Button(action: {
                    textInserter.debugStrategyOrder = order
                }) {
                    HStack {
                        if textInserter.debugStrategyOrder == order {
                            Image(systemName: "checkmark")
                        }
                        Text(order.rawValue)
                    }
                }
            }
            
            Divider()
            
            Text("Current: \(textInserter.getCurrentStrategyOrder())")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
#endif