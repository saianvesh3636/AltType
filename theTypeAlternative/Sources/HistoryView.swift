import SwiftUI
import AppKit

struct HistoryView: View {
    @EnvironmentObject var transcriptionStore: TranscriptionStore
    @EnvironmentObject var paletteManager: PaletteManager
    @State private var searchText = ""
    @State private var selectedEntry: TranscriptionEntry?
    
    private var filteredHistory: [TranscriptionEntry] {
        if searchText.isEmpty {
            return transcriptionStore.transcriptionHistory
        } else {
            return transcriptionStore.transcriptionHistory.filter {
                $0.text.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var groupedHistory: [HistorySection] {
        let calendar = Calendar.current
        let now = Date()
        
        // Group entries by date
        let grouped = Dictionary(grouping: filteredHistory) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
        
        // Convert to sections and sort by date (newest first)
        return grouped.map { date, entries in
            let sectionTitle = dateTitle(for: date, relativeTo: now, calendar: calendar)
            return HistorySection(
                title: sectionTitle,
                date: date,
                entries: entries.sorted { $0.timestamp > $1.timestamp } // Newest first within section
            )
        }.sorted { $0.date > $1.date } // Newest sections first
    }
    
    private func dateTitle(for date: Date, relativeTo now: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Day of week
            return formatter.string(from: date)
        } else if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d" // Month and day
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy" // Full date for older entries
            return formatter.string(from: date)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Search Bar
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("History")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color.appOnSurface(from: paletteManager))
                        
                        Text("View and manage your past transcriptions")
                            .font(.subheadline)
                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Text("\(transcriptionStore.transcriptionHistory.count) entries")
                            .font(.subheadline)
                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                        
                        Button("Export All") {
                            exportHistory()
                        }
                        .buttonStyle(.bordered)
                        .disabled(transcriptionStore.transcriptionHistory.isEmpty)
                        
                        Button("Clear All") {
                            clearHistory()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(Color.appError(from: paletteManager))
                        .disabled(transcriptionStore.transcriptionHistory.isEmpty)
                    }
                }
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                    
                    TextField("Search transcriptions...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.appSurface(from: paletteManager))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 24)
            .background(Color.appBackground(from: paletteManager))
            
            // Content
            if filteredHistory.isEmpty {
                EmptyHistoryView(hasEntries: !transcriptionStore.transcriptionHistory.isEmpty)
            } else {
                GroupedHistoryListView(
                    sections: groupedHistory,
                    selectedEntry: $selectedEntry
                )
            }
        }
        .background(Color.appBackground(from: paletteManager))
        .navigationTitle("")
    }
    
    private func exportHistory() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "transcription_history.txt"
        
        if savePanel.runModal() == .OK {
            guard let url = savePanel.url else { return }
            
            let content = transcriptionStore.transcriptionHistory.map { entry in
                "[\(entry.formattedTime)] \(entry.text)"
            }.joined(separator: "\n\n")
            
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    private func clearHistory() {
        let alert = NSAlert()
        alert.messageText = "Clear All History?"
        alert.informativeText = "This action cannot be undone. All transcription history will be permanently deleted."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")
        
        // Make the alert dismissible by clicking outside
        if let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn {
                    withAnimation(.easeOut(duration: 0.3)) {
                        transcriptionStore.clearHistory()
                    }
                    
                    // Also clear the SpeechLogger history
                    Task { @MainActor in
                        SpeechLogger.shared.clearHistory()
                    }
                }
            }
        } else {
            // Fallback to modal if no window is available
            if alert.runModal() == .alertFirstButtonReturn {
                withAnimation(.easeOut(duration: 0.3)) {
                    transcriptionStore.clearHistory()
                }
                
                // Also clear the SpeechLogger history
                Task { @MainActor in
                    SpeechLogger.shared.clearHistory()
                }
            }
        }
    }
}

struct EmptyHistoryView: View {
    let hasEntries: Bool
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: hasEntries ? "magnifyingglass" : "clock")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
            
            VStack(spacing: 8) {
                Text(hasEntries ? "No Results Found" : "No History Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(hasEntries ? "Try adjusting your search terms" : "Start using voice dictation to see your transcriptions here")
                    .font(.subheadline)
                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

struct GroupedHistoryListView: View {
    let sections: [HistorySection]
    @Binding var selectedEntry: TranscriptionEntry?
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(sections, id: \.date) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        // Section Header
                        HStack {
                            Text(section.title)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.appOnSurface(from: paletteManager))
                            
                            Spacer()
                            
                            Text("\(section.entries.count) \(section.entries.count == 1 ? "entry" : "entries")")
                                .font(.caption)
                                .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.appSecondary(from: paletteManager).opacity(0.3))
                                )
                        }
                        .padding(.horizontal, 32)
                        
                        // Section Entries
                        LazyVStack(spacing: 8) {
                            ForEach(section.entries) { entry in
                                HistoryEntryRow(
                                    entry: entry,
                                    isSelected: selectedEntry?.id == entry.id
                                ) {
                                    selectedEntry = entry
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                }
            }
            .padding(.bottom, 32)
        }
    }
}

struct HistoryListView: View {
    let entries: [TranscriptionEntry]
    @Binding var selectedEntry: TranscriptionEntry?
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(entries) { entry in
                    HistoryEntryRow(
                        entry: entry,
                        isSelected: selectedEntry?.id == entry.id
                    ) {
                        selectedEntry = entry
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

struct HistoryEntryRow: View {
    let entry: TranscriptionEntry
    let isSelected: Bool
    let onSelect: () -> Void
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: 4) {
                    Circle()
                        .fill(Color.appAccent(from: paletteManager))
                        .frame(width: 8, height: 8)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                }
                .frame(height: 60)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(entry.formattedTime)
                            .font(.caption)
                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.appSecondary(from: paletteManager).opacity(0.3))
                            )
                        
                        if let duration = entry.duration {
                            Text("\(Int(duration))s")
                                .font(.caption)
                                .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Button(action: { copyToClipboard(entry.text) }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                                    .padding(8)
                            }
                            .buttonStyle(IconHoverButtonStyle())
                            .help("Copy to clipboard")
                            
                            Button(action: { shareText(entry.text) }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.caption)
                                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                                    .padding(8)
                            }
                            .buttonStyle(IconHoverButtonStyle())
                            .help("Share")
                        }
                    }
                    
                    Text(entry.text)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .lineLimit(isSelected ? nil : 3)
                        .textSelection(.enabled)
                    
                    if !isSelected && entry.text.count > 150 {
                        Text("Tap to expand...")
                            .font(.caption)
                            .foregroundColor(Color.appAccent(from: paletteManager))
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.appAccent(from: paletteManager).opacity(0.05) : Color.appSurface(from: paletteManager))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.appAccent(from: paletteManager).opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func shareText(_ text: String) {
        let sharingService = NSSharingService(named: .composeMessage)
        sharingService?.perform(withItems: [text])
    }
}

// MARK: - Data Models

struct HistorySection {
    let title: String
    let date: Date
    let entries: [TranscriptionEntry]
}

// // #Preview {
//     let store = TranscriptionStore()
//     
//     // Add sample data for today
//     
//     // Today's entries
//     store.addTranscription(text: "This is a transcription from today.", confidence: 0.85, duration: 3.2)
//     store.addTranscription(text: "Another entry from earlier today with some longer text.", confidence: 0.92, duration: 5.1)
//     
//     // Note: In preview, we can't easily modify the store's internal array to add entries 
//     // from other dates, but the sectioned view will still work with today's entries.
//     // In the real app, entries from different dates will be properly sectioned.
//     
//     return HistoryView()
//         .environmentObject(store)
//         .frame(width: 800, height: 600)
// }
