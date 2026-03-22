import SwiftUI
import PhotosUI

struct UploadPrescriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AIExtractionService.self) private var aiService
    @Environment(DataService.self) private var dataService
    @State private var currentStep: UploadStep = .prescription
    @State private var prescriptionImage: UIImage?
    @State private var medicineImages: [UIImage] = []
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var medicinePhotoItems: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var showExtraction = false
    @State private var episodeTitle = ""
    @State private var extractionResult: AIExtractionService.ExtractionResult?
    @State private var errorMessage: String?
    @State private var showManualEntry = false

    enum UploadStep: Int, CaseIterable {
        case prescription = 0
        case medicine = 1
        case processing = 2
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Step indicator
                stepIndicator

                ScrollView {
                    VStack(spacing: MCSpacing.lg) {
                        switch currentStep {
                        case .prescription:
                            prescriptionStep
                        case .medicine:
                            medicineStep
                        case .processing:
                            processingStep
                        }
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)
                    .padding(.vertical, MCSpacing.lg)
                }
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Upload Prescription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showExtraction) {
                if let result = extractionResult {
                    ConfirmationView(extractionResult: result, episodeTitle: episodeTitle)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image in
                    prescriptionImage = image
                }
            }
            .sheet(isPresented: $showManualEntry) {
                ManualMedicineEntryView(episodeTitle: episodeTitle.isEmpty ? "New Episode" : episodeTitle)
            }
            .alert("Extraction Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("Try Again") { errorMessage = nil }
                Button("Enter Manually") {
                    errorMessage = nil
                    showManualEntry = true
                }
            } message: {
                Text(errorMessage ?? "Something went wrong while reading your prescription.")
            }
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: MCSpacing.xs) {
            ForEach(UploadStep.allCases, id: \.rawValue) { step in
                VStack(spacing: MCSpacing.xxs) {
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue ? MCColors.primaryTeal : MCColors.textTertiary.opacity(0.3))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Group {
                                if step.rawValue < currentStep.rawValue {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                } else {
                                    Text("\(step.rawValue + 1)")
                                        .font(MCTypography.captionBold)
                                        .foregroundStyle(step.rawValue <= currentStep.rawValue ? .white : MCColors.textTertiary)
                                }
                            }
                        )

                    Text(stepTitle(step))
                        .font(MCTypography.caption)
                        .foregroundStyle(step == currentStep ? MCColors.primaryTeal : MCColors.textTertiary)
                }

                if step != .processing {
                    Rectangle()
                        .fill(step.rawValue < currentStep.rawValue ? MCColors.primaryTeal : MCColors.textTertiary.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
        .padding(.vertical, MCSpacing.md)
        .background(MCColors.cardBackground)
    }

    // MARK: - Prescription Step

    private var prescriptionStep: some View {
        VStack(spacing: MCSpacing.lg) {
            // Info card
            MCAccentCard(accent: MCColors.info) {
                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(MCColors.info)
                        Text("Prescription Photo")
                            .font(MCTypography.bodyMedium)
                    }
                    Text("Take a clear photo of your handwritten prescription. This helps us identify the doctor, diagnosis, and medication details.")
                        .font(MCTypography.footnote)
                        .foregroundStyle(MCColors.textSecondary)
                }
            }

            // Episode title
            MCTextField(label: "Episode Title", icon: "text.quote", text: $episodeTitle)

            // Image picker area
            if let image = prescriptionImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))

                    Button {
                        prescriptionImage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    .padding(MCSpacing.xs)
                }
            } else {
                imagePickerPlaceholder(
                    icon: "doc.text.viewfinder",
                    title: "Add Prescription Photo",
                    subtitle: "Take a photo or choose from gallery"
                )
            }

            // Photo picker — gallery
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                HStack(spacing: MCSpacing.xs) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Choose from Gallery")
                        .font(MCTypography.headline)
                }
                .foregroundStyle(MCColors.primaryTeal)
                .frame(maxWidth: .infinity)
                .frame(height: MCSpacing.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                        .stroke(MCColors.primaryTeal, lineWidth: 2)
                )
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        prescriptionImage = image
                    }
                }
            }

            // Camera button
            Button {
                showCamera = true
            } label: {
                HStack(spacing: MCSpacing.xs) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Take Photo")
                        .font(MCTypography.headline)
                }
                .foregroundStyle(MCColors.accentCoral)
                .frame(maxWidth: .infinity)
                .frame(height: MCSpacing.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                        .stroke(MCColors.accentCoral, lineWidth: 2)
                )
            }

            // Next button
            MCPrimaryButton("Next: Medicine Photos", icon: "arrow.right") {
                withAnimation {
                    currentStep = .medicine
                }
            }
            .disabled(episodeTitle.isEmpty)
            .opacity(episodeTitle.isEmpty ? 0.6 : 1)

            // Skip option
            Button("Skip - enter manually") {
                withAnimation {
                    currentStep = .medicine
                }
            }
            .font(MCTypography.footnote)
            .foregroundStyle(MCColors.textTertiary)
        }
    }

    // MARK: - Medicine Step

    private var medicineStep: some View {
        VStack(spacing: MCSpacing.lg) {
            MCAccentCard(accent: MCColors.success) {
                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    HStack {
                        Image(systemName: "pills.circle.fill")
                            .foregroundStyle(MCColors.success)
                        Text("Medicine Packaging Photos")
                            .font(MCTypography.bodyMedium)
                    }
                    Text("Take photos of each medicine strip/box. This is the primary source for accurate brand names, dosage, and expiry dates.")
                        .font(MCTypography.footnote)
                        .foregroundStyle(MCColors.textSecondary)
                }
            }

            // Medicine images grid
            if !medicineImages.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MCSpacing.sm) {
                    ForEach(Array(medicineImages.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))

                            Button {
                                medicineImages.remove(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white)
                                    .shadow(radius: 2)
                            }
                            .padding(4)
                        }
                    }

                    // Add more button
                    if medicineImages.count < 10 {
                        PhotosPicker(selection: $medicinePhotoItems, maxSelectionCount: 10 - medicineImages.count, matching: .images) {
                            VStack(spacing: MCSpacing.xs) {
                                Image(systemName: "plus")
                                    .font(.system(size: 24))
                                Text("Add more")
                                    .font(MCTypography.caption)
                            }
                            .foregroundStyle(MCColors.primaryTeal)
                            .frame(height: 120)
                            .frame(maxWidth: .infinity)
                            .background(MCColors.primaryTeal.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                            .overlay(
                                RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                    .foregroundStyle(MCColors.primaryTeal.opacity(0.3))
                            )
                        }
                    }
                }
            } else {
                PhotosPicker(selection: $medicinePhotoItems, maxSelectionCount: 10, matching: .images) {
                    imagePickerPlaceholder(
                        icon: "pills",
                        title: "Add Medicine Photos",
                        subtitle: "Photo each medicine strip/box"
                    )
                }
            }

            // Extraction error inline
            if let error = errorMessage {
                MCErrorView(
                    "Extraction Failed",
                    message: error,
                    retryAction: {
                        errorMessage = nil
                        processImages()
                    }
                )

                Button("Enter Manually Instead") {
                    errorMessage = nil
                    showManualEntry = true
                }
                .font(MCTypography.bodyMedium)
                .foregroundStyle(MCColors.primaryTeal)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(MCColors.primaryTeal.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            } else {
                // Process button
                MCCoralButton("Extract with AI", icon: "wand.and.stars", isLoading: aiService.isExtracting) {
                    processImages()
                }

                Button("Enter manually instead") {
                    showManualEntry = true
                }
                .font(MCTypography.footnote)
                .foregroundStyle(MCColors.textTertiary)
            }
        }
        .onChange(of: medicinePhotoItems) { _, newItems in
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        medicineImages.append(image)
                    }
                }
                medicinePhotoItems = []
            }
        }
    }

    // MARK: - Processing Step

    private var processingStep: some View {
        VStack(spacing: MCSpacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(MCColors.backgroundLight, lineWidth: 6)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: aiService.extractionProgress)
                    .stroke(MCColors.primaryTeal, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: aiService.extractionProgress)

                VStack {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 32))
                        .foregroundStyle(MCColors.primaryTeal)
                    Text("\(Int(aiService.extractionProgress * 100))%")
                        .font(MCTypography.headline)
                        .foregroundStyle(MCColors.textPrimary)
                }
            }

            VStack(spacing: MCSpacing.xs) {
                Text("Extracting prescription data...")
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)

                Text(progressStepText)
                    .font(MCTypography.footnote)
                    .foregroundStyle(MCColors.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Helpers

    private func imagePickerPlaceholder(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: MCSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(MCColors.primaryTeal.opacity(0.5))

            Text(title)
                .font(MCTypography.bodyMedium)
                .foregroundStyle(MCColors.textPrimary)

            Text(subtitle)
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(MCColors.primaryTeal.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundStyle(MCColors.primaryTeal.opacity(0.2))
        )
    }

    private func stepTitle(_ step: UploadStep) -> String {
        switch step {
        case .prescription: return "Rx Photo"
        case .medicine: return "Medicine"
        case .processing: return "Extract"
        }
    }

    private var progressStepText: String {
        switch aiService.extractionProgress {
        case 0..<0.3: return "Uploading images..."
        case 0.3..<0.6: return "AI reading prescription..."
        case 0.6..<0.8: return "Cross-referencing medicine packaging..."
        case 0.8..<1.0: return "Validating with pharmacy database..."
        default: return "Complete!"
        }
    }

    private func processImages() {
        withAnimation {
            currentStep = .processing
        }

        Task {
            do {
                let result = try await aiService.extractFromImages(
                    prescriptionImage: prescriptionImage?.jpegData(compressionQuality: 0.7),
                    medicineImages: medicineImages.compactMap { $0.jpegData(compressionQuality: 0.7) }
                )
                extractionResult = result
                showExtraction = true
            } catch {
                errorMessage = error.localizedDescription
                withAnimation {
                    currentStep = .medicine
                }
            }
        }
    }
}

// MARK: - Camera Picker (UIImagePickerController wrapper)

struct CameraPicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked, dismiss: dismiss)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (UIImage) -> Void
        let dismiss: DismissAction

        init(onImagePicked: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onImagePicked = onImagePicked
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
