import SwiftUI
import SwiftData

struct DoctorListView: View {
    @Environment(DataService.self) private var dataService
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Doctor.name) private var doctors: [Doctor]

    @State private var showAddDoctor = false
    @State private var searchText = ""

    private var filteredDoctors: [Doctor] {
        if searchText.isEmpty { return doctors }
        return doctors.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.specialty.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if doctors.isEmpty {
                    emptyState
                } else {
                    doctorList
                }
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddDoctor = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(MCColors.primaryTeal)
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(MCColors.textTertiary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search doctors")
            .sheet(isPresented: $showAddDoctor) {
                AddDoctorSheet()
                    .environment(dataService)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: MCSpacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(MCColors.primaryTeal.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(MCColors.primaryTeal)
            }

            VStack(spacing: MCSpacing.xs) {
                Text("No Linked Doctors")
                    .font(MCTypography.title)
                    .foregroundStyle(MCColors.textPrimary)

                Text("Add your doctor to message them directly.")
                    .font(MCTypography.body)
                    .foregroundStyle(MCColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MCSpacing.xl)
            }

            Button {
                showAddDoctor = true
            } label: {
                HStack(spacing: MCSpacing.xs) {
                    Image(systemName: "person.badge.plus")
                    Text("Add Doctor")
                        .fontWeight(.semibold)
                }
                .font(MCTypography.bodyMedium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MCSpacing.sm)
                .background(MCColors.primaryTeal)
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            }
            .padding(.horizontal, MCSpacing.xxl)

            Spacer()
        }
    }

    // MARK: - Doctor List

    private var doctorList: some View {
        List {
            ForEach(filteredDoctors) { doctor in
                NavigationLink {
                    DoctorMessageView(doctor: doctor)
                } label: {
                    doctorRow(doctor)
                }
                .listRowBackground(MCColors.cardBackground)
                .listRowSeparator(.hidden)
            }
            .onDelete(perform: deleteDoctors)
        }
        .listStyle(.plain)
    }

    // MARK: - Doctor Row

    private func doctorRow(_ doctor: Doctor) -> some View {
        HStack(spacing: MCSpacing.sm) {
            // Avatar with online indicator
            ZStack(alignment: .bottomTrailing) {
                Text(doctor.avatarEmoji)
                    .font(.system(size: 28))
                    .frame(width: MCSpacing.avatarSize, height: MCSpacing.avatarSize)
                    .background(MCColors.primaryTeal.opacity(0.1))
                    .clipShape(Circle())

                Circle()
                    .fill(doctor.isOnline ? MCColors.success : MCColors.textTertiary)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(MCColors.cardBackground, lineWidth: 2)
                    )
                    .offset(x: 2, y: 2)
            }

            // Doctor info
            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                Text(doctor.name)
                    .font(MCTypography.bodyMedium)
                    .foregroundStyle(MCColors.textPrimary)

                Text(doctor.specialty)
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.primaryTeal)

                if !doctor.phone.isEmpty {
                    Text(doctor.phone)
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if doctor.consultationFee > 0 {
                VStack(alignment: .trailing, spacing: MCSpacing.xxs) {
                    Text("\u{20B9}\(Int(doctor.consultationFee))")
                        .font(MCTypography.captionBold)
                        .foregroundStyle(MCColors.primaryTeal)
                    Text("Fee")
                        .font(.system(size: 9))
                        .foregroundStyle(MCColors.textTertiary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(MCColors.textTertiary)
        }
        .padding(.vertical, MCSpacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(doctor.name), \(doctor.specialty)")
    }

    // MARK: - Actions

    private func deleteDoctors(at offsets: IndexSet) {
        for index in offsets {
            let doctor = filteredDoctors[index]
            dataService.modelContext.delete(doctor)
        }
        try? dataService.modelContext.save()
    }
}

// MARK: - Add Doctor Sheet

struct AddDoctorSheet: View {
    @Environment(DataService.self) private var dataService
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var specialty = "General Physician"
    @State private var phone = ""
    @State private var email = ""
    @State private var registrationNumber = ""
    @State private var consultationFee = ""

    private let specialties = [
        "General Physician",
        "Cardiologist",
        "Neurologist",
        "Orthopedic",
        "Dermatologist",
        "ENT Specialist",
        "Ophthalmologist",
        "Pulmonologist",
        "Gastroenterologist",
        "Endocrinologist",
        "Psychiatrist",
        "Pediatrician",
        "Gynecologist",
        "Urologist",
        "Oncologist",
        "Nephrologist",
        "Ayurvedic",
        "Homeopathic",
        "Other"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Doctor Details") {
                    TextField("Full Name", text: $name)
                        .textContentType(.name)

                    Picker("Specialty", selection: $specialty) {
                        ForEach(specialties, id: \.self) { spec in
                            Text(spec).tag(spec)
                        }
                    }
                }

                Section("Contact") {
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)

                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }

                Section("Registration") {
                    TextField("Registration Number (optional)", text: $registrationNumber)
                        .textInputAutocapitalization(.characters)

                    TextField("Consultation Fee (optional)", text: $consultationFee)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Doctor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDoctor()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveDoctor() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let doctor = Doctor(
            name: trimmedName,
            specialty: specialty,
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            registrationNumber: registrationNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            consultationFee: Double(consultationFee) ?? 0
        )

        dataService.modelContext.insert(doctor)
        try? dataService.modelContext.save()

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
    }
}
