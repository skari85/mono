//
//  AppleNotesView.swift
//  Mono
//
//  Apple Notes Integration View
//

import SwiftUI

struct AppleNotesView: View {
    @StateObject private var notesManager = AppleNotesManager.shared
    @State private var searchText = ""
    @State private var showingCreateNote = false
    @State private var newNoteTitle = ""
    @State private var newNoteContent = ""
    @State private var selectedNote: EKNote?
    @State private var showingNoteDetail = false
    
    var filteredNotes: [EKNote] {
        if searchText.isEmpty {
            return notesManager.notes
        } else {
            return notesManager.searchNotes(query: searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                notesHeader
                
                // Content
                if notesManager.hasNotesAccess {
                    if filteredNotes.isEmpty {
                        emptyStateView
                    } else {
                        notesListView
                    }
                } else {
                    accessDeniedView
                }
            }
            .navigationTitle("Apple Notes")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCreateNote) {
                createNoteView
            }
            .sheet(isPresented: $showingNoteDetail) {
                if let note = selectedNote {
                    noteDetailView(note)
                }
            }
        }
    }
    
    private var notesHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Notes Integration")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(notesManager.notes.count) notes available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showingCreateNote = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search notes...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }
    
    private var notesListView: some View {
        List {
            ForEach(filteredNotes) { note in
                NoteCard(note: note) {
                    selectedNote = note
                    showingNoteDetail = true
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Notes Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first note or check your Notes app")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create Note") {
                showingCreateNote = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var accessDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 64))
                .foregroundColor(.red)
            
            Text("Notes Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please grant access to your Notes app to use this feature")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Grant Access") {
                notesManager.requestNotesAccess()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var createNoteView: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Note Title", text: $newNoteTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.headline)
                
                TextField("Note Content", text: $newNoteContent, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(10...20)
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingCreateNote = false
                        newNoteTitle = ""
                        newNoteContent = ""
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            let success = await notesManager.createNote(
                                title: newNoteTitle,
                                content: newNoteContent
                            )
                            if success {
                                showingCreateNote = false
                                newNoteTitle = ""
                                newNoteContent = ""
                            }
                        }
                    }
                    .disabled(newNoteTitle.isEmpty || newNoteContent.isEmpty)
                }
            }
        }
    }
    
    private func noteDetailView(_ note: EKNote) -> some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(note.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Text("Created: \(note.createdDate.formatted())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("Modified: \(note.modifiedDate.formatted())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("\(note.wordCount) words")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Content
                    Text(note.content)
                        .font(.body)
                        .lineSpacing(4)
                }
                .padding()
            }
            .navigationTitle("Note Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingNoteDetail = false
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct NoteCard: View {
    let note: EKNote
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(note.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(note.modifiedDate, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(note.preview)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                HStack {
                    Text("\(note.wordCount) words")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(note.createdDate, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AppleNotesView()
}
