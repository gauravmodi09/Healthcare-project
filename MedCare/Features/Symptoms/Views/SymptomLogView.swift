import SwiftData
import SwiftUI

struct SymptomLogView: View {
    let episodeId: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(DataService.self) private var dataService

    // MARK: - State

    @State private var currentStep = 0
    @State private var selectedFeeling: FeelingLevel = .okay
    @State private var selectedSymptoms: Set<String> = []
    @State private var painLevel: Double = 3
    @State private var notes = ""
    @State private var showConfetti = false
    @State private var isSaving = false

    private let totalSteps = 5

    // MARK: - Symptom Data

    private struct SymptomItem: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
    }

    private let commonSymptoms: [SymptomItem] = [
        SymptomItem(name: "Headache", icon: "brain.head.profile"),
        SymptomItem(name: "Nausea", icon: "stomach"),
        SymptomItem(name: "Fatigue", icon: "battery.25percent"),
        SymptomItem(name: "Dizziness", icon: "tornado"),
        SymptomItem(name: "Pain", icon: "bolt.fill"),
        SymptomItem(name: "Fever", icon: "thermometer.high"),
        SymptomItem(name: "Cough", icon: "lungs.fill"),
        SymptomItem(name: "Insomnia", icon: "moon.zzz.fill"),
        SymptomItem(name: "Anxiety", icon: "brain"),
        SymptomItem(name: "Appetite Loss", icon: "fork.knife"),
    ]

    // MARK: - Computed

    private var hasPainSelected: Bool {
        selectedSymptoms.contains("Pain")
    }

    /// Actual number of visible steps (skip pain step if no pain selected)
    private var visibleStepCount: Int {
        hasPainSelected ? totalSteps : totalSteps - 1
    }

    /// Map logical step index to step type
    private var currentStepType: StepType {
        switch currentStep {
        case 0: return .feeling
        case 1: return .symptoms
        case 2: return hasPainSelected ? .pain : .notes
        case 3: return hasPainSelected ? .notes : .summary
        case 4: return .summary
        default: return .summary
        }
    }

    private var canAdvance: Bool {
        switch currentStepType {
        case .feeling: return true
        case .symptoms: return true
        case .pain: return true
        case .notes: return true
        case .summary: return false
        }
    }

    private var isLastStep: Bool {
        currentStepType == .summary
    }

    private enum StepType {
        case feeling, symptoms, pain, notes, summary
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                MCColors.backgroundLight
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress dots
                    progressDots
                        .padding(.top, MCSpacing.md)
                        .padding(.bottom, MCSpacing.lg)

                    // Step content
                    TabView(selection: $currentStep) {
                        feelingStep.tag(0)
                        symptomsStep.tag(1)
                        if hasPainSelected {
                            painStep.tag(2)
                            notesStep.tag(3)
                            summaryStep.tag(4)
                        } else {
                            notesStep.tag(2)
                            summaryStep.tag(3)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: currentStep)

                    // Navigation buttons
                    navigationButtons
                        .padding(.horizontal, MCSpacing.screenPadding)
                        .padding(.bottom, MCSpacing.lg)
                }

                // Confetti overlay
                if showConfetti {
                    ConfettiOverlay()
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
            .navigationTitle("Daily Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MCColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: MCSpacing.xs) {
            ForEach(0..<visibleStepCount, id: \.self) { index in
                Circle()
                    .fill(index <= currentStep ? MCColors.primaryTeal : MCColors.divider)
                    .frame(width: index == currentStep ? 10 : 8, height: index == currentStep ? 10 : 8)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
    }

    // MARK: - Step 1: Feeling

    private var feelingStep: some View {
        VStack(spacing: MCSpacing.xl) {
            Spacer().frame(height: MCSpacing.lg)

            Text("How are you feeling?")
                .font(MCTypography.display)
                .foregroundStyle(MCColors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Tap the emoji that best describes your mood today")
                .font(MCTypography.body)
                .foregroundStyle(MCColors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer().frame(height: MCSpacing.md)

            HStack(spacing: MCSpacing.sm) {
                ForEach(FeelingLevel.allCases, id: \.self) { level in
                    feelingButton(level)
                }
            }
            .padding(.horizontal, MCSpacing.screenPadding)

            Spacer()
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private func feelingButton(_ level: FeelingLevel) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                selectedFeeling = level
            }
        } label: {
            VStack(spacing: MCSpacing.xs) {
                Text(level.emoji)
                    .font(.system(size: selectedFeeling == level ? 48 : 36))
                    .scaleEffect(selectedFeeling == level ? 1.1 : 1.0)

                Text(level.label)
                    .font(MCTypography.caption)
                    .foregroundStyle(selectedFeeling == level ? MCColors.primaryTeal : MCColors.textTertiary)
                    .fontWeight(selectedFeeling == level ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MCSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                    .fill(selectedFeeling == level ? MCColors.primaryTeal.opacity(0.12) : MCColors.cardBackground)
                    .shadow(color: selectedFeeling == level ? MCColors.primaryTeal.opacity(0.2) : .clear, radius: 8, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                    .stroke(selectedFeeling == level ? MCColors.primaryTeal : MCColors.divider, lineWidth: selectedFeeling == level ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedFeeling)
    }

    // MARK: - Step 2: Symptoms

    private var symptomsStep: some View {
        ScrollView {
            VStack(spacing: MCSpacing.xl) {
                Spacer().frame(height: MCSpacing.lg)

                Text("Any specific symptoms?")
                    .font(MCTypography.display)
                    .foregroundStyle(MCColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Select all that apply — or skip if none")
                    .font(MCTypography.body)
                    .foregroundStyle(MCColors.textSecondary)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: MCSpacing.sm)

                // Symptoms grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: MCSpacing.sm),
                    GridItem(.flexible(), spacing: MCSpacing.sm),
                ], spacing: MCSpacing.sm) {
                    ForEach(commonSymptoms) { symptom in
                        symptomChip(symptom)
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)

                Spacer().frame(height: MCSpacing.lg)
            }
            .padding(.horizontal, MCSpacing.screenPadding)
        }
        .scrollIndicators(.hidden)
    }

    private func symptomChip(_ symptom: SymptomItem) -> some View {
        let isSelected = selectedSymptoms.contains(symptom.name)

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                if isSelected {
                    selectedSymptoms.remove(symptom.name)
                } else {
                    selectedSymptoms.insert(symptom.name)
                }
            }
        } label: {
            HStack(spacing: MCSpacing.xs) {
                Image(systemName: symptom.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? .white : MCColors.primaryTeal)

                Text(symptom.name)
                    .font(MCTypography.subheadline)
                    .foregroundStyle(isSelected ? .white : MCColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: MCSpacing.touchTargetLarge)
            .background(
                RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                    .fill(isSelected ? MCColors.primaryTeal : MCColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                    .stroke(isSelected ? MCColors.primaryTeal : MCColors.divider, lineWidth: isSelected ? 0 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 3: Pain Level

    private var painStep: some View {
        VStack(spacing: MCSpacing.xl) {
            Spacer().frame(height: MCSpacing.lg)

            Text("Pain level")
                .font(MCTypography.display)
                .foregroundStyle(MCColors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Slide to indicate your pain intensity")
                .font(MCTypography.body)
                .foregroundStyle(MCColors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer().frame(height: MCSpacing.xl)

            // Large pain number
            Text("\(Int(painLevel))")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(painColor)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.15), value: Int(painLevel))

            Text(painDescription)
                .font(MCTypography.headline)
                .foregroundStyle(painColor)
                .animation(.easeInOut, value: Int(painLevel))

            Spacer().frame(height: MCSpacing.md)

            // Pain slider
            VStack(spacing: MCSpacing.xs) {
                Slider(value: $painLevel, in: 1...10, step: 1)
                    .tint(painColor)
                    .padding(.horizontal, MCSpacing.screenPadding)

                HStack {
                    Text("1")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textTertiary)
                    Spacer()
                    Text("10")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textTertiary)
                }
                .padding(.horizontal, MCSpacing.screenPadding + MCSpacing.xxs)
            }

            Spacer()
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private var painColor: Color {
        let level = Int(painLevel)
        switch level {
        case 1...3: return MCColors.success
        case 4...6: return MCColors.warning
        case 7...8: return Color(hex: "F97066")
        default: return MCColors.error
        }
    }

    private var painDescription: String {
        let level = Int(painLevel)
        switch level {
        case 1...2: return "Barely noticeable"
        case 3...4: return "Mild discomfort"
        case 5...6: return "Moderate pain"
        case 7...8: return "Severe pain"
        case 9: return "Very severe"
        default: return "Worst possible"
        }
    }

    // MARK: - Step 4: Notes

    private var notesStep: some View {
        VStack(spacing: MCSpacing.xl) {
            Spacer().frame(height: MCSpacing.lg)

            Text("Anything else?")
                .font(MCTypography.display)
                .foregroundStyle(MCColors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Add any additional notes (optional)")
                .font(MCTypography.body)
                .foregroundStyle(MCColors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer().frame(height: MCSpacing.md)

            TextEditor(text: $notes)
                .font(MCTypography.body)
                .foregroundStyle(MCColors.textPrimary)
                .frame(height: 150)
                .padding(MCSpacing.sm)
                .background(MCColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                        .stroke(MCColors.divider, lineWidth: 1)
                )
                .scrollContentBackground(.hidden)
                .padding(.horizontal, MCSpacing.screenPadding)

            Spacer()
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Step 5: Summary

    private var summaryStep: some View {
        ScrollView {
            VStack(spacing: MCSpacing.lg) {
                Spacer().frame(height: MCSpacing.md)

                Text("Summary")
                    .font(MCTypography.display)
                    .foregroundStyle(MCColors.textPrimary)

                Text("Review your check-in before saving")
                    .font(MCTypography.body)
                    .foregroundStyle(MCColors.textSecondary)

                Spacer().frame(height: MCSpacing.sm)

                // Feeling card
                summaryCard(title: "Feeling", icon: "heart.fill") {
                    HStack(spacing: MCSpacing.xs) {
                        Text(selectedFeeling.emoji)
                            .font(.system(size: 28))
                        Text(selectedFeeling.label)
                            .font(MCTypography.title2)
                            .foregroundStyle(MCColors.textPrimary)
                    }
                }

                // Symptoms card
                if !selectedSymptoms.isEmpty {
                    summaryCard(title: "Symptoms", icon: "list.bullet.clipboard") {
                        FlowLayout(spacing: MCSpacing.xs) {
                            ForEach(Array(selectedSymptoms).sorted(), id: \.self) { symptom in
                                Text(symptom)
                                    .font(MCTypography.footnote)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, MCSpacing.sm)
                                    .padding(.vertical, MCSpacing.xs)
                                    .background(MCColors.primaryTeal)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Pain card
                if hasPainSelected {
                    summaryCard(title: "Pain Level", icon: "bolt.fill") {
                        HStack(spacing: MCSpacing.xs) {
                            Text("\(Int(painLevel))/10")
                                .font(MCTypography.title)
                                .foregroundStyle(painColor)
                            Text("—")
                                .foregroundStyle(MCColors.textTertiary)
                            Text(painDescription)
                                .font(MCTypography.body)
                                .foregroundStyle(MCColors.textSecondary)
                        }
                    }
                }

                // Notes card
                if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    summaryCard(title: "Notes", icon: "note.text") {
                        Text(notes)
                            .font(MCTypography.body)
                            .foregroundStyle(MCColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Spacer().frame(height: MCSpacing.md)
            }
            .padding(.horizontal, MCSpacing.screenPadding)
        }
        .scrollIndicators(.hidden)
    }

    private func summaryCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            HStack(spacing: MCSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MCColors.primaryTeal)
                Text(title)
                    .font(MCTypography.subheadline)
                    .foregroundStyle(MCColors.textSecondary)
                    .textCase(.uppercase)
                    .kerning(1.0)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MCSpacing.cardPadding)
        .background(MCColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                .stroke(MCColors.divider, lineWidth: 1)
        )
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: MCSpacing.sm) {
            // Back button
            if currentStep > 0 {
                MCSecondaryButton("Back", icon: "chevron.left") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep -= 1
                    }
                }
            }

            // Next / Save button
            if isLastStep {
                MCPrimaryButton("Save Check-in", icon: "checkmark.circle.fill", isLoading: isSaving) {
                    saveLog()
                }
            } else {
                MCPrimaryButton("Next", icon: "chevron.right") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        // Skip pain step if pain not selected
                        currentStep += 1
                    }
                }
            }
        }
    }

    // MARK: - Save

    private func saveLog() {
        isSaving = true

        // Fetch episode by ID and save via DataService
        let descriptor = FetchDescriptor<Episode>(predicate: #Predicate { $0.id == episodeId })
        guard let episode = try? dataService.modelContext.fetch(descriptor).first else {
            isSaving = false
            return
        }

        let notesText = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        _ = dataService.addSymptomLog(
            to: episode,
            feeling: selectedFeeling,
            symptoms: buildSymptomEntries(),
            notes: notesText.isEmpty ? nil : notesText
        )

        // Show confetti then dismiss
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showConfetti = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }

    private func buildSymptomEntries() -> [SymptomEntry] {
        selectedSymptoms.map { name in
            let severity: SeverityLevel = {
                if name == "Pain" {
                    switch Int(painLevel) {
                    case 1...3: return .mild
                    case 4...6: return .moderate
                    case 7...8: return .severe
                    default: return .critical
                    }
                }
                return .mild
            }()
            return SymptomEntry(name: name, severity: severity)
        }
    }
}

// MARK: - Confetti Overlay

private struct ConfettiOverlay: View {
    @State private var particles: [ConfettiParticle] = []

    struct ConfettiParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        let color: Color
        let size: CGFloat
        let rotation: Double
        let velocityX: CGFloat
        let velocityY: CGFloat
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for particle in particles {
                    let rect = CGRect(
                        x: particle.x - particle.size / 2,
                        y: particle.y - particle.size / 2,
                        width: particle.size,
                        height: particle.size * 0.6
                    )
                    context.fill(
                        RoundedRectangle(cornerRadius: 2).path(in: rect),
                        with: .color(particle.color)
                    )
                }
            }
        }
        .onAppear {
            generateParticles()
            animateParticles()
        }
    }

    private func generateParticles() {
        let colors: [Color] = [
            MCColors.primaryTeal,
            MCColors.accentCoral,
            MCColors.success,
            MCColors.warning,
            MCColors.info,
            Color(hex: "A78BFA"),
        ]

        particles = (0..<60).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 50...350),
                y: -20,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...12),
                rotation: Double.random(in: 0...360),
                velocityX: CGFloat.random(in: -3...3),
                velocityY: CGFloat.random(in: 2...6)
            )
        }
    }

    private func animateParticles() {
        Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { timer in
            var allOffScreen = true
            for i in particles.indices {
                particles[i].x += particles[i].velocityX
                particles[i].y += particles[i].velocityY
                if particles[i].y < 900 {
                    allOffScreen = false
                }
            }
            if allOffScreen {
                timer.invalidate()
            }
        }
    }
}
