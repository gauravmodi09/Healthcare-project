import SwiftUI
import SwiftData

/// Full-screen document viewer with metadata, edit, share, and delete
struct DocumentDetailView: View {
    let documentId: UUID
    @Environment(DataService.self) private var dataService
    @Environment(\.dismiss) private var dismiss
    @Query private var allImages: [EpisodeImage]
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var zoomScale: CGFloat = 1.0

    private var document: EpisodeImage? {
        allImages.first { $0.id == documentId }
    }

    var body: some View {
        if let doc = document {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    // Image viewer
                    imageViewer(doc)

                    // Metadata card
                    metadataCard(doc)

                    // Notes
                    if let notes = doc.notes, !notes.isEmpty {
                        MCCard {
                            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                                HStack(spacing: MCSpacing.xs) {
                                    Image(systemName: "note.text")
                                        .foregroundStyle(MCColors.primaryTeal)
                                    Text("Notes")
                                        .font(MCTypography.subheadline)
                                        .foregroundStyle(MCColors.textPrimary)
                                }
                                Text(notes)
                                    .font(MCTypography.body)
                                    .foregroundStyle(MCColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, MCSpacing.screenPadding)
                    }
                }
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle(doc.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showEditSheet = true
                    } label: {
                        Image(systemName: "pencil")
                    }

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(MCColors.error)
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditDocumentView(document: doc)
            }
            .alert("Delete Document?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    dataService.deleteDocument(doc)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently remove \"\(doc.displayTitle)\" and cannot be undone.")
            }
        } else {
            ContentUnavailableView("Document not found", systemImage: "doc.questionmark")
        }
    }

    // MARK: - Image Viewer

    private func imageViewer(_ doc: EpisodeImage) -> some View {
        Group {
            if let localPath = doc.localPath,
               let uiImage = UIImage(contentsOfFile: localPath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                    .scaleEffect(zoomScale)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                zoomScale = max(1.0, min(value.magnification, 4.0))
                            }
                            .onEnded { _ in
                                withAnimation { zoomScale = 1.0 }
                            }
                    )
                    .padding(.horizontal, MCSpacing.screenPadding)
            } else {
                // No image placeholder
                VStack(spacing: MCSpacing.md) {
                    Image(systemName: doc.imageType.icon)
                        .font(.system(size: 56))
                        .foregroundStyle(Color(hex: doc.imageType.displayColor))
                    Text("No photo attached")
                        .font(MCTypography.body)
                        .foregroundStyle(MCColors.textSecondary)
                    Text("Edit to add a photo")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color(hex: doc.imageType.displayColor).opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                .padding(.horizontal, MCSpacing.screenPadding)
            }
        }
    }

    // MARK: - Metadata Card

    private func metadataCard(_ doc: EpisodeImage) -> some View {
        MCCard {
            VStack(spacing: MCSpacing.sm) {
                metadataRow(icon: "doc.text", label: "Type", value: doc.imageType.rawValue, color: Color(hex: doc.imageType.displayColor))

                Divider()

                metadataRow(icon: "calendar", label: "Added", value: doc.createdAt.formatted(date: .abbreviated, time: .shortened))

                if let episode = doc.episode {
                    Divider()
                    metadataRow(icon: "heart.text.clipboard", label: "Episode", value: episode.title, color: MCColors.primaryTeal)
                }

                if let fileSize = doc.fileSize {
                    Divider()
                    metadataRow(icon: "internaldrive", label: "Size", value: formatFileSize(fileSize))
                }

                Divider()

                HStack(spacing: MCSpacing.xs) {
                    Image(systemName: "arrow.up.circle")
                        .foregroundStyle(uploadStatusColor(doc.uploadStatus))
                        .frame(width: 24)
                    Text("Upload Status")
                        .font(MCTypography.footnote)
                        .foregroundStyle(MCColors.textSecondary)
                    Spacer()
                    MCBadge(doc.uploadStatus.rawValue.capitalized, color: uploadStatusColor(doc.uploadStatus))
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private func metadataRow(icon: String, label: String, value: String, color: Color = MCColors.textPrimary) -> some View {
        HStack(spacing: MCSpacing.xs) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
                .font(MCTypography.footnote)
                .foregroundStyle(MCColors.textSecondary)
            Spacer()
            Text(value)
                .font(MCTypography.footnote)
                .foregroundStyle(MCColors.textPrimary)
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }

    private func uploadStatusColor(_ status: UploadStatus) -> Color {
        switch status {
        case .pending: return MCColors.textTertiary
        case .uploading: return MCColors.info
        case .uploaded: return MCColors.success
        case .failed: return MCColors.error
        }
    }
}

// MARK: - Edit Document Sheet

struct EditDocumentView: View {
    let document: EpisodeImage
    @Environment(DataService.self) private var dataService
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var selectedType: ImageType = .prescription

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    // Type
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Document Type")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: MCSpacing.xs) {
                            ForEach(ImageType.allCases, id: \.self) { type in
                                Button {
                                    selectedType = type
                                } label: {
                                    VStack(spacing: MCSpacing.xxs) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 18))
                                            .foregroundStyle(Color(hex: type.displayColor))
                                        Text(type.rawValue)
                                            .font(.system(size: 9))
                                            .foregroundStyle(MCColors.textPrimary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(selectedType == type ? Color(hex: type.displayColor).opacity(0.1) : MCColors.backgroundLight)
                                    .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                                    .overlay(
                                        selectedType == type
                                            ? RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall)
                                                .stroke(Color(hex: type.displayColor), lineWidth: 1.5)
                                            : nil
                                    )
                                }
                            }
                        }
                    }

                    MCTextField(label: "Title", icon: "tag", text: $title)

                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Notes")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                            .padding(MCSpacing.xs)
                            .background(MCColors.backgroundLight)
                            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                            .overlay(
                                RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall)
                                    .stroke(MCColors.textTertiary.opacity(0.3), lineWidth: 1)
                            )
                    }

                    MCPrimaryButton("Save Changes", icon: "checkmark") {
                        dataService.updateDocument(
                            document,
                            title: title.isEmpty ? nil : title,
                            notes: notes.isEmpty ? nil : notes,
                            imageType: selectedType
                        )
                        dismiss()
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.vertical, MCSpacing.lg)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Edit Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                title = document.title ?? ""
                notes = document.notes ?? ""
                selectedType = document.imageType
            }
        }
    }
}
