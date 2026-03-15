import SwiftUI
import PhotosUI

/// Sheet for adding a new document to an episode
struct AddDocumentView: View {
    let episode: Episode
    @Environment(\.dismiss) private var dismiss
    @Environment(DataService.self) private var dataService
    @State private var selectedType: ImageType = .prescription
    @State private var title = ""
    @State private var notes = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    // Document type picker
                    typePickerSection

                    // Image selection
                    imageSection

                    // Title
                    MCTextField(label: "Title", icon: "tag", text: $title)

                    // Notes
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Notes (optional)")
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

                    // Save button
                    MCPrimaryButton(isSaving ? "Saving..." : "Save Document", icon: "square.and.arrow.down") {
                        saveDocument()
                    }
                    .disabled(title.isEmpty || isSaving)
                    .opacity(title.isEmpty ? 0.6 : 1)
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.vertical, MCSpacing.lg)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Add Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Type Picker

    private var typePickerSection: some View {
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
                                .font(.system(size: 20))
                                .foregroundStyle(Color(hex: type.displayColor))
                            Text(type.rawValue)
                                .font(.system(size: 10))
                                .foregroundStyle(MCColors.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
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
    }

    // MARK: - Image Section

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.xs) {
            Text("Attach Photo")
                .font(MCTypography.subheadline)
                .foregroundStyle(MCColors.textSecondary)

            if let image = selectedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))

                    Button {
                        selectedImage = nil
                        selectedPhotoItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }
                    .offset(x: -8, y: 8)
                }
            } else {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    VStack(spacing: MCSpacing.sm) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(MCColors.primaryTeal)
                        Text("Tap to select photo")
                            .font(MCTypography.footnote)
                            .foregroundStyle(MCColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(MCColors.primaryTeal.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                            .foregroundStyle(MCColors.primaryTeal.opacity(0.3))
                    )
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
            }
        }
    }

    // MARK: - Save

    private func saveDocument() {
        isSaving = true

        var localPath: String?
        var fileSize: Int64?

        // Save image to disk if selected
        if let image = selectedImage,
           let data = image.jpegData(compressionQuality: 0.7) {
            let filename = "\(UUID().uuidString).jpg"
            localPath = dataService.saveImageToDocuments(data, filename: filename)
            fileSize = Int64(data.count)
        }

        let _ = dataService.addDocument(
            to: episode,
            imageType: selectedType,
            localPath: localPath,
            title: title.isEmpty ? nil : title,
            notes: notes.isEmpty ? nil : notes,
            fileSize: fileSize
        )

        dismiss()
    }
}
