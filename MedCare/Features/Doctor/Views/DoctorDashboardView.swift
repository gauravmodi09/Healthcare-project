import SwiftUI

// MARK: - Mock Data Models

struct DoctorMockPatient: Identifiable {
    let id = UUID()
    let name: String
    let age: Int
    let avatarEmoji: String
    let primaryCondition: String
    let status: PatientStatus
    let lastVitalLabel: String
    let lastVitalValue: String
    let lastVitalTime: String
    let adherencePercent: Int
    let heartRate: Int
    let bpSystolic: Int
    let bpDiastolic: Int
    let spO2: Int
    let glucose: Int
    let hrTrend: VitalTrend
    let bpTrend: VitalTrend
    let spO2Trend: VitalTrend
    let glucoseTrend: VitalTrend
    let medications: [DoctorMockMedication]
    let recentSymptoms: [DoctorMockSymptom]
    let dailyAdherence7Days: [Int]
}

struct DoctorMockMedication: Identifiable {
    let id = UUID()
    let name: String
    let dosage: String
    let frequency: String
    let adherencePercent: Int
}

struct DoctorMockSymptom: Identifiable {
    let id = UUID()
    let name: String
    let severity: String
    let daysAgo: Int
}

enum PatientStatus: String {
    case critical = "Critical"
    case warning = "Needs Attention"
    case stable = "Stable"

    var color: Color {
        switch self {
        case .critical: return MCColors.error
        case .warning: return MCColors.warning
        case .stable: return MCColors.success
        }
    }

    var icon: String {
        switch self {
        case .critical: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .stable: return "checkmark.circle.fill"
        }
    }
}

enum VitalTrend: String {
    case up = "arrow.up.right"
    case down = "arrow.down.right"
    case stable = "arrow.right"
}

struct DoctorAlert: Identifiable {
    let id = UUID()
    let patientName: String
    let message: String
    let severity: PatientStatus
    let timeAgo: String
}

// MARK: - Mock Data Provider

enum DoctorMockData {
    static let alerts: [DoctorAlert] = [
        DoctorAlert(patientName: "Ramesh", message: "BP exceeded 160/100 today", severity: .critical, timeAgo: "2h ago"),
        DoctorAlert(patientName: "Priya", message: "Missed 3 doses this week", severity: .warning, timeAgo: "4h ago"),
        DoctorAlert(patientName: "Suresh", message: "Blood glucose at 280 mg/dL", severity: .critical, timeAgo: "6h ago"),
        DoctorAlert(patientName: "Anita", message: "SpO2 dropped to 91%", severity: .warning, timeAgo: "1d ago"),
    ]

    static let patients: [DoctorMockPatient] = [
        DoctorMockPatient(
            name: "Ramesh Kumar", age: 58, avatarEmoji: "\u{1F468}\u{200D}\u{1F9B3}",
            primaryCondition: "Hypertension",
            status: .critical,
            lastVitalLabel: "BP", lastVitalValue: "162/98", lastVitalTime: "2h ago",
            adherencePercent: 72,
            heartRate: 88, bpSystolic: 162, bpDiastolic: 98, spO2: 96, glucose: 142,
            hrTrend: .up, bpTrend: .up, spO2Trend: .stable, glucoseTrend: .up,
            medications: [
                DoctorMockMedication(name: "Amlodipine", dosage: "5mg", frequency: "Once Daily", adherencePercent: 85),
                DoctorMockMedication(name: "Telmisartan", dosage: "40mg", frequency: "Once Daily", adherencePercent: 60),
                DoctorMockMedication(name: "Ecosprin", dosage: "75mg", frequency: "Once Daily", adherencePercent: 72),
            ],
            recentSymptoms: [
                DoctorMockSymptom(name: "Headache", severity: "Moderate", daysAgo: 0),
                DoctorMockSymptom(name: "Dizziness", severity: "Mild", daysAgo: 1),
                DoctorMockSymptom(name: "Chest tightness", severity: "Mild", daysAgo: 3),
            ],
            dailyAdherence7Days: [100, 67, 100, 33, 100, 67, 100]
        ),
        DoctorMockPatient(
            name: "Priya Sharma", age: 45, avatarEmoji: "\u{1F469}",
            primaryCondition: "Type 2 Diabetes",
            status: .warning,
            lastVitalLabel: "Glucose", lastVitalValue: "186 mg/dL", lastVitalTime: "4h ago",
            adherencePercent: 58,
            heartRate: 76, bpSystolic: 128, bpDiastolic: 82, spO2: 98, glucose: 186,
            hrTrend: .stable, bpTrend: .stable, spO2Trend: .stable, glucoseTrend: .up,
            medications: [
                DoctorMockMedication(name: "Metformin", dosage: "500mg", frequency: "Twice Daily", adherencePercent: 50),
                DoctorMockMedication(name: "Glimepiride", dosage: "1mg", frequency: "Once Daily", adherencePercent: 65),
                DoctorMockMedication(name: "Atorvastatin", dosage: "10mg", frequency: "Once Daily", adherencePercent: 58),
            ],
            recentSymptoms: [
                DoctorMockSymptom(name: "Fatigue", severity: "Moderate", daysAgo: 1),
                DoctorMockSymptom(name: "Blurred vision", severity: "Mild", daysAgo: 4),
            ],
            dailyAdherence7Days: [50, 50, 100, 0, 100, 50, 50]
        ),
        DoctorMockPatient(
            name: "Suresh Patel", age: 62, avatarEmoji: "\u{1F474}",
            primaryCondition: "Diabetes + CAD",
            status: .critical,
            lastVitalLabel: "Glucose", lastVitalValue: "280 mg/dL", lastVitalTime: "6h ago",
            adherencePercent: 45,
            heartRate: 92, bpSystolic: 148, bpDiastolic: 92, spO2: 95, glucose: 280,
            hrTrend: .up, bpTrend: .up, spO2Trend: .down, glucoseTrend: .up,
            medications: [
                DoctorMockMedication(name: "Insulin Glargine", dosage: "20 units", frequency: "Once Daily", adherencePercent: 40),
                DoctorMockMedication(name: "Metformin", dosage: "1000mg", frequency: "Twice Daily", adherencePercent: 50),
                DoctorMockMedication(name: "Clopidogrel", dosage: "75mg", frequency: "Once Daily", adherencePercent: 45),
            ],
            recentSymptoms: [
                DoctorMockSymptom(name: "Excessive thirst", severity: "Severe", daysAgo: 0),
                DoctorMockSymptom(name: "Frequent urination", severity: "Moderate", daysAgo: 0),
                DoctorMockSymptom(name: "Numbness in feet", severity: "Mild", daysAgo: 2),
            ],
            dailyAdherence7Days: [33, 67, 33, 0, 67, 33, 67]
        ),
        DoctorMockPatient(
            name: "Anita Desai", age: 52, avatarEmoji: "\u{1F469}\u{200D}\u{1F9B3}",
            primaryCondition: "Asthma + Hypothyroid",
            status: .warning,
            lastVitalLabel: "SpO2", lastVitalValue: "93%", lastVitalTime: "1d ago",
            adherencePercent: 80,
            heartRate: 82, bpSystolic: 118, bpDiastolic: 76, spO2: 93, glucose: 98,
            hrTrend: .stable, bpTrend: .stable, spO2Trend: .down, glucoseTrend: .stable,
            medications: [
                DoctorMockMedication(name: "Budecort Inhaler", dosage: "200mcg", frequency: "Twice Daily", adherencePercent: 90),
                DoctorMockMedication(name: "Thyronorm", dosage: "50mcg", frequency: "Once Daily", adherencePercent: 95),
                DoctorMockMedication(name: "Montelukast", dosage: "10mg", frequency: "Once Daily", adherencePercent: 55),
            ],
            recentSymptoms: [
                DoctorMockSymptom(name: "Wheezing", severity: "Moderate", daysAgo: 1),
                DoctorMockSymptom(name: "Shortness of breath", severity: "Mild", daysAgo: 3),
            ],
            dailyAdherence7Days: [100, 67, 100, 100, 67, 67, 100]
        ),
        DoctorMockPatient(
            name: "Vikram Singh", age: 35, avatarEmoji: "\u{1F468}",
            primaryCondition: "GERD",
            status: .stable,
            lastVitalLabel: "BP", lastVitalValue: "120/78", lastVitalTime: "1d ago",
            adherencePercent: 92,
            heartRate: 72, bpSystolic: 120, bpDiastolic: 78, spO2: 99, glucose: 96,
            hrTrend: .stable, bpTrend: .stable, spO2Trend: .stable, glucoseTrend: .stable,
            medications: [
                DoctorMockMedication(name: "Pantoprazole", dosage: "40mg", frequency: "Once Daily", adherencePercent: 95),
                DoctorMockMedication(name: "Domperidone", dosage: "10mg", frequency: "Thrice Daily", adherencePercent: 88),
            ],
            recentSymptoms: [],
            dailyAdherence7Days: [100, 100, 100, 100, 67, 100, 100]
        ),
    ]
}

// MARK: - Doctor Dashboard View

struct DoctorDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPatient: DoctorMockPatient?
    @State private var searchText = ""

    private let alerts = DoctorMockData.alerts
    private let patients = DoctorMockData.patients

    private var filteredPatients: [DoctorMockPatient] {
        if searchText.isEmpty { return patients }
        return patients.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.primaryCondition.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var alertPatients: [DoctorMockPatient] {
        patients.filter { $0.status != .stable }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.sectionSpacing) {
                    doctorHeader
                    alertPanel
                    patientListSection
                }
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Doctor Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search patients...")
            .sheet(item: $selectedPatient) { patient in
                DoctorPatientDetailView(patient: patient)
            }
        }
    }

    // MARK: - Doctor Header

    private var doctorHeader: some View {
        MCCard {
            HStack(spacing: MCSpacing.md) {
                ZStack {
                    Circle()
                        .fill(MCColors.primaryGradient)
                        .frame(width: 56, height: 56)
                    Image(systemName: "stethoscope")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    Text("Dr. Anil Mehta")
                        .font(MCTypography.title2)
                        .foregroundStyle(MCColors.textPrimary)
                    Text("General Medicine")
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.textSecondary)
                    HStack(spacing: MCSpacing.xxs) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 11))
                        Text("\(patients.count) patients")
                            .font(MCTypography.captionBold)
                    }
                    .foregroundStyle(MCColors.primaryTeal)
                    .padding(.horizontal, MCSpacing.xs)
                    .padding(.vertical, MCSpacing.xxs)
                    .background(MCColors.primaryTeal.opacity(0.1))
                    .clipShape(Capsule())
                }

                Spacer()

                VStack(spacing: MCSpacing.xxs) {
                    Text("\(alertPatients.count)")
                        .font(MCTypography.metric)
                        .foregroundStyle(MCColors.error)
                    Text("Alerts")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Alert Panel

    private var alertPanel: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundStyle(MCColors.error)
                Text("NEEDS ATTENTION")
                    .font(MCTypography.sectionHeader)
                    .foregroundStyle(MCColors.textSecondary)
                    .kerning(1.2)
                Spacer()
                MCBadge("\(alerts.count)", color: MCColors.error, style: .filled)
            }
            .padding(.horizontal, MCSpacing.screenPadding)

            VStack(spacing: MCSpacing.xs) {
                ForEach(alerts) { alert in
                    MCAccentCard(accent: alert.severity.color) {
                        HStack(spacing: MCSpacing.sm) {
                            Image(systemName: alert.severity.icon)
                                .foregroundStyle(alert.severity.color)
                                .font(.system(size: 16, weight: .semibold))

                            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                                HStack(spacing: MCSpacing.xxs) {
                                    Text(alert.patientName)
                                        .font(MCTypography.headline)
                                        .foregroundStyle(MCColors.textPrimary)
                                    Text(alert.timeAgo)
                                        .font(MCTypography.caption)
                                        .foregroundStyle(MCColors.textTertiary)
                                }
                                Text(alert.message)
                                    .font(MCTypography.callout)
                                    .foregroundStyle(MCColors.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(MCColors.textTertiary)
                        }
                    }
                }
            }
            .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    // MARK: - Patient List

    private var patientListSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(MCColors.primaryTeal)
                Text("ALL PATIENTS")
                    .font(MCTypography.sectionHeader)
                    .foregroundStyle(MCColors.textSecondary)
                    .kerning(1.2)
                Spacer()
            }
            .padding(.horizontal, MCSpacing.screenPadding)

            VStack(spacing: MCSpacing.xs) {
                ForEach(filteredPatients) { patient in
                    Button {
                        selectedPatient = patient
                    } label: {
                        patientRow(patient)
                    }
                }
            }
            .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    private func patientRow(_ patient: DoctorMockPatient) -> some View {
        MCCard {
            HStack(spacing: MCSpacing.sm) {
                // Status dot + Avatar
                ZStack(alignment: .bottomTrailing) {
                    Text(patient.avatarEmoji)
                        .font(.system(size: 28))
                        .frame(width: 48, height: 48)
                        .background(MCColors.backgroundLight)
                        .clipShape(Circle())

                    Circle()
                        .fill(patient.status.color)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(MCColors.cardBackground, lineWidth: 2))
                        .offset(x: 2, y: 2)
                }

                // Name, condition, vital
                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    HStack(spacing: MCSpacing.xxs) {
                        Text(patient.name)
                            .font(MCTypography.headline)
                            .foregroundStyle(MCColors.textPrimary)
                        Text("\(patient.age)y")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                    }
                    Text(patient.primaryCondition)
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.textSecondary)
                    HStack(spacing: MCSpacing.xxs) {
                        Text("\(patient.lastVitalLabel): \(patient.lastVitalValue)")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                        Text(patient.lastVitalTime)
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                    }
                }

                Spacer()

                // Adherence badge
                VStack(spacing: MCSpacing.xxs) {
                    Text("\(patient.adherencePercent)%")
                        .font(MCTypography.captionBold)
                        .foregroundStyle(adherenceColor(patient.adherencePercent))
                    Text("Adherence")
                        .font(.system(size: 9))
                        .foregroundStyle(MCColors.textTertiary)
                }
                .padding(.horizontal, MCSpacing.xs)
                .padding(.vertical, MCSpacing.xxs)
                .background(adherenceColor(patient.adherencePercent).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MCColors.textTertiary)
            }
        }
    }

    private func adherenceColor(_ percent: Int) -> Color {
        switch percent {
        case 0..<50: return MCColors.error
        case 50..<75: return MCColors.warning
        case 75..<90: return MCColors.info
        default: return MCColors.success
        }
    }
}

#Preview {
    DoctorDashboardView()
}
