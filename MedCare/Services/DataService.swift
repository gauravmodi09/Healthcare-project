import Foundation
import SwiftData
import SwiftUI

/// Central data management service using SwiftData
@Observable
final class DataService {
    let modelContainer: ModelContainer
    let modelContext: ModelContext

    init() {
        let schema = Schema([
            User.self,
            UserProfile.self,
            Episode.self,
            Medicine.self,
            DoseLog.self,
            CareTask.self,
            SymptomLog.self,
            EpisodeImage.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: config)
            modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    // MARK: - User Management

    func getOrCreateUser(phoneNumber: String) -> User {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.phoneNumber == phoneNumber }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let user = User(phoneNumber: phoneNumber)
        modelContext.insert(user)
        save()
        return user
    }

    // MARK: - Profile Management

    func createProfile(for user: User, name: String, relation: ProfileRelation, dob: Date?, gender: Gender?) -> UserProfile {
        let profile = UserProfile(name: name, relation: relation, dateOfBirth: dob, gender: gender, avatarEmoji: relation.emoji)
        // Deactivate other profiles
        user.profiles.forEach { $0.isActive = false }
        profile.isActive = true
        profile.user = user
        user.profiles.append(profile)
        save()
        return profile
    }

    func switchActiveProfile(to profile: UserProfile, for user: User) {
        user.profiles.forEach { $0.isActive = false }
        profile.isActive = true
        save()
    }

    // MARK: - Episode Management

    func createEpisode(for profile: UserProfile, title: String, type: EpisodeType, doctorName: String? = nil, diagnosis: String? = nil) -> Episode {
        let episode = Episode(title: title, episodeType: type, doctorName: doctorName, diagnosis: diagnosis)
        episode.profile = profile
        profile.episodes.append(episode)
        modelContext.insert(episode)
        save()
        return episode
    }

    func activateEpisode(_ episode: Episode) {
        episode.status = .active
        episode.updatedAt = Date()
        save()
    }

    func completeEpisode(_ episode: Episode) {
        episode.status = .completed
        episode.endDate = Date()
        episode.updatedAt = Date()
        save()
    }

    // MARK: - Medicine Management

    func addMedicine(to episode: Episode, brandName: String, dosage: String, frequency: MedicineFrequency, timing: [MedicineTiming], duration: Int?, source: MedicineSource = .manual, confidence: Double = 1.0) -> Medicine {
        let medicine = Medicine(
            brandName: brandName,
            dosage: dosage,
            frequency: frequency,
            timing: timing,
            duration: duration,
            source: source,
            confidenceScore: confidence
        )
        medicine.episode = episode
        episode.medicines.append(medicine)
        modelContext.insert(medicine)
        save()
        return medicine
    }

    // MARK: - Dose Logging

    func createDoseLogs(for medicine: Medicine, days: Int = 7) {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday) else { continue }

            for time in medicine.timing {
                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = time.hour
                components.minute = time.minute

                guard let scheduledTime = calendar.date(from: components) else { continue }

                let log = DoseLog(scheduledTime: scheduledTime)
                log.medicine = medicine
                medicine.doseLogs.append(log)
                modelContext.insert(log)
            }
        }
        save()
    }

    func logDose(_ doseLog: DoseLog, status: DoseStatus, notes: String? = nil) {
        switch status {
        case .taken:
            doseLog.markTaken()
        case .skipped:
            doseLog.markSkipped(reason: notes)
        case .snoozed:
            doseLog.markSnoozed()
        default:
            doseLog.status = status
        }
        save()
    }

    // MARK: - Symptom Logging

    func addSymptomLog(to episode: Episode, feeling: FeelingLevel, symptoms: [SymptomEntry], notes: String?) -> SymptomLog {
        let log = SymptomLog(overallFeeling: feeling, symptoms: symptoms)
        log.notes = notes
        log.episode = episode
        episode.symptomLogs.append(log)
        modelContext.insert(log)
        save()
        return log
    }

    // MARK: - Care Tasks

    func addTask(to episode: Episode, title: String, type: CareTaskType, dueDate: Date?) -> CareTask {
        let task = CareTask(title: title, taskType: type, dueDate: dueDate)
        task.episode = episode
        episode.tasks.append(task)
        modelContext.insert(task)
        save()
        return task
    }

    func toggleTask(_ task: CareTask) {
        task.isCompleted.toggle()
        save()
    }

    // MARK: - Queries

    func activeEpisodes(for profile: UserProfile) -> [Episode] {
        profile.episodes.filter { $0.status == .active }
    }

    func todaysDoses(for profile: UserProfile) -> [DoseLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return profile.episodes
            .flatMap { $0.medicines }
            .filter { $0.isActive }
            .flatMap { $0.doseLogs }
            .filter { $0.scheduledTime >= startOfDay && $0.scheduledTime < endOfDay }
            .sorted { $0.scheduledTime < $1.scheduledTime }
    }

    func upcomingDoses(for profile: UserProfile, limit: Int = 5) -> [DoseLog] {
        let now = Date()
        return todaysDoses(for: profile)
            .filter { $0.scheduledTime > now && $0.status == .pending }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - File Management

    func addDocument(to episode: Episode, imageType: ImageType, localPath: String? = nil, title: String? = nil, notes: String? = nil, fileSize: Int64? = nil) -> EpisodeImage {
        let doc = EpisodeImage(imageType: imageType, localPath: localPath, title: title)
        doc.notes = notes
        doc.fileSize = fileSize
        doc.episode = episode
        episode.images.append(doc)
        modelContext.insert(doc)
        save()
        return doc
    }

    func deleteDocument(_ document: EpisodeImage) {
        // Clean up local files
        if let path = document.localPath {
            deleteLocalFile(at: path)
        }
        if let thumbPath = document.thumbnailPath {
            deleteLocalFile(at: thumbPath)
        }
        modelContext.delete(document)
        save()
    }

    func updateDocument(_ document: EpisodeImage, title: String? = nil, notes: String? = nil, imageType: ImageType? = nil) {
        if let title { document.title = title }
        if let notes { document.notes = notes }
        if let imageType { document.imageType = imageType }
        save()
    }

    func documentsForEpisode(_ episode: Episode, filterType: ImageType? = nil) -> [EpisodeImage] {
        let images = episode.images
        let filtered = filterType == nil ? images : images.filter { $0.imageType == filterType }
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }

    func allDocumentsForProfile(_ profile: UserProfile, filterType: ImageType? = nil) -> [EpisodeImage] {
        let allImages = profile.episodes.flatMap { $0.images }
        let filtered = filterType == nil ? allImages : allImages.filter { $0.imageType == filterType }
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }

    func documentCountsByType(for profile: UserProfile) -> [ImageType: Int] {
        var counts: [ImageType: Int] = [:]
        for image in profile.episodes.flatMap({ $0.images }) {
            counts[image.imageType, default: 0] += 1
        }
        return counts
    }

    func saveImageToDocuments(_ imageData: Data, filename: String) -> String? {
        let fileManager = FileManager.default
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let patientFilesDir = documentsDir.appendingPathComponent("PatientFiles", isDirectory: true)

        try? fileManager.createDirectory(at: patientFilesDir, withIntermediateDirectories: true)

        let fileURL = patientFilesDir.appendingPathComponent(filename)
        do {
            try imageData.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }

    func deleteLocalFile(at path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }

    // MARK: - Seed Demo Data

    func seedDemoData() -> User {
        let cal = Calendar.current
        let now = Date()

        let user = User(phoneNumber: "9876543210")
        modelContext.insert(user)

        // ──────────────────────────────────────────────
        // MARK: Profile 1 — Rahul (Self, 30M)
        // ──────────────────────────────────────────────
        let rahul = UserProfile(
            name: "Rahul",
            relation: .myself,
            dateOfBirth: cal.date(byAdding: .year, value: -30, to: now),
            gender: .male,
            avatarEmoji: "👨"
        )
        rahul.user = user
        rahul.isActive = true
        rahul.bloodGroup = "B+"
        rahul.knownConditions = ["Mild Asthma", "Seasonal Allergies"]
        rahul.allergies = ["Sulfa drugs"]
        user.profiles.append(rahul)

        // --- Episode 1: Cold & Cough (active) ---
        let coldEp = Episode(
            title: "Cold & Cough",
            episodeType: .acute,
            doctorName: "Dr. Priya Mehta",
            diagnosis: "Upper Respiratory Infection"
        )
        coldEp.status = .active
        coldEp.profile = rahul
        rahul.episodes.append(coldEp)

        // Medicines
        let augmentin = makeMedicine(
            brand: "Augmentin 625 Duo", generic: "Amoxicillin + Clavulanic Acid",
            dosage: "625mg", freq: .twiceDaily, timing: [.morning, .night],
            duration: 5, source: .aiExtracted, confidence: 0.95,
            instructions: "After food", manufacturer: "GlaxoSmithKline", mrp: 228.50,
            episode: coldEp
        )
        let pan40 = makeMedicine(
            brand: "Pan 40", generic: "Pantoprazole",
            dosage: "40mg", freq: .onceDaily, timing: [.morning],
            duration: 5, source: .aiExtracted, confidence: 0.91,
            instructions: "Before food on empty stomach", manufacturer: "Alkem", mrp: 115,
            episode: coldEp
        )
        let montekLC = makeMedicine(
            brand: "Montek LC", generic: "Montelukast + Levocetirizine",
            dosage: "10mg", freq: .onceDaily, timing: [.night],
            duration: 7, source: .aiExtracted, confidence: 0.72,
            instructions: "After dinner", manufacturer: "Sun Pharma", mrp: 165,
            episode: coldEp
        )
        let alexCough = makeMedicine(
            brand: "Alex Cough Syrup", generic: "Dextromethorphan + CPM",
            dosage: "10ml", freq: .thriceDaily, timing: [.morning, .afternoon, .night],
            duration: 5, source: .manual, confidence: 1.0,
            instructions: "After meals", manufacturer: "Glenmark", mrp: 95,
            episode: coldEp
        )

        // Dose logs with realistic adherence
        for med in [augmentin, pan40, montekLC, alexCough] {
            createDoseLogsWithAdherence(for: med, days: 5, adherenceRate: 0.85)
        }

        // Symptom logs — recovery trajectory over 4 days
        let symptomData: [(Int, FeelingLevel, [(String, SeverityLevel)])] = [
            (-3, .terrible, [("Cough", .severe), ("Sore Throat", .severe), ("Fever", .moderate), ("Body Ache", .moderate)]),
            (-2, .bad, [("Cough", .severe), ("Sore Throat", .moderate), ("Runny Nose", .moderate), ("Fever", .mild)]),
            (-1, .okay, [("Cough", .moderate), ("Runny Nose", .mild), ("Fatigue", .mild)]),
            (0, .good, [("Cough", .mild), ("Runny Nose", .mild)])
        ]
        for (dayOffset, feeling, symptoms) in symptomData {
            let entries = symptoms.map { SymptomEntry(name: $0.0, severity: $0.1) }
            let log = SymptomLog(overallFeeling: feeling, symptoms: entries)
            log.date = cal.date(byAdding: .day, value: dayOffset, to: now) ?? now
            log.episode = coldEp
            coldEp.symptomLogs.append(log)
            modelContext.insert(log)
        }

        // Tasks
        addSeedTask("Follow-up with Dr. Mehta", type: .followUp, daysFromNow: 4, episode: coldEp)
        addSeedTask("CBC Blood Test", type: .labTest, daysFromNow: 2, episode: coldEp)
        addSeedTask("Buy steam inhaler", type: .other, daysFromNow: 1, episode: coldEp)
        addSeedTask("Drink warm fluids 3x daily", type: .lifestyle, daysFromNow: 0, episode: coldEp, completed: true)

        // Documents
        addSeedDoc(.prescription, title: "Dr. Mehta's Prescription", notes: "Original handwritten prescription from clinic visit, 3 medicines for 5 days", episode: coldEp)
        addSeedDoc(.labReport, title: "CBC Blood Test Report", notes: "Complete blood count — WBC elevated at 12,400, rest normal", episode: coldEp)
        addSeedDoc(.bill, title: "Apollo Pharmacy Bill", notes: "Medicine purchase receipt — Rs. 508.50 total", episode: coldEp)
        addSeedDoc(.scan, title: "Chest X-Ray", notes: "PA view — no consolidation, no pleural effusion", episode: coldEp)
        addSeedDoc(.medicinePackaging, title: "Augmentin 625 Duo Strip", notes: "Photo of medicine strip with batch & expiry info", episode: coldEp)

        // --- Episode 2: Knee Ligament Sprain (completed) ---
        let kneeEp = Episode(
            title: "Knee Ligament Sprain",
            episodeType: .acute,
            doctorName: "Dr. Vikram Singh",
            diagnosis: "Grade 2 MCL Sprain — Right Knee"
        )
        kneeEp.status = .completed
        kneeEp.startDate = cal.date(byAdding: .month, value: -2, to: now) ?? now
        kneeEp.endDate = cal.date(byAdding: .month, value: -1, to: now)
        kneeEp.profile = rahul
        rahul.episodes.append(kneeEp)

        let zerodol = makeMedicine(
            brand: "Zerodol SP", generic: "Aceclofenac + Paracetamol + Serratiopeptidase",
            dosage: "100mg", freq: .twiceDaily, timing: [.morning, .night],
            duration: 7, source: .manual, confidence: 1.0,
            instructions: "After food", manufacturer: "IPCA", mrp: 142,
            episode: kneeEp
        )
        zerodol.isActive = false
        let pregab = makeMedicine(
            brand: "Pregabalin M 75", generic: "Pregabalin + Methylcobalamin",
            dosage: "75mg", freq: .onceDaily, timing: [.night],
            duration: 14, source: .manual, confidence: 1.0,
            instructions: "After dinner", manufacturer: "Torrent", mrp: 198,
            episode: kneeEp
        )
        pregab.isActive = false

        addSeedTask("MRI Right Knee", type: .labTest, daysFromNow: -50, episode: kneeEp, completed: true)
        addSeedTask("Physiotherapy sessions (12)", type: .followUp, daysFromNow: -40, episode: kneeEp, completed: true)
        addSeedTask("Follow-up with Dr. Vikram", type: .followUp, daysFromNow: -30, episode: kneeEp, completed: true)

        addSeedDoc(.scan, title: "MRI Right Knee", notes: "Grade 2 MCL tear, no ACL involvement, mild joint effusion", episode: kneeEp)
        addSeedDoc(.prescription, title: "Dr. Vikram's Prescription", notes: "Pain management + physiotherapy referral for 12 sessions", episode: kneeEp)
        addSeedDoc(.doctorNote, title: "Physio Progress Note", notes: "Completed 12/12 sessions, ROM restored to 95%, cleared for light activity", episode: kneeEp)
        addSeedDoc(.bill, title: "Fortis Hospital Bill", notes: "Consultation + MRI — Rs. 8,500", episode: kneeEp)
        addSeedDoc(.insuranceDoc, title: "Insurance Claim Receipt", notes: "Star Health claim #CLM-2026-4521 — Rs. 6,800 approved", episode: kneeEp)

        // ──────────────────────────────────────────────
        // MARK: Profile 2 — Mom (Parent, 58F)
        // ──────────────────────────────────────────────
        let mom = UserProfile(
            name: "Mom",
            relation: .parent,
            dateOfBirth: cal.date(byAdding: .year, value: -58, to: now),
            gender: .female,
            avatarEmoji: "👩"
        )
        mom.user = user
        mom.isActive = false
        mom.bloodGroup = "O+"
        mom.knownConditions = ["Type 2 Diabetes", "Hypertension", "Hypothyroid"]
        mom.allergies = ["Penicillin"]
        user.profiles.append(mom)

        // --- Episode: Diabetes Management (chronic) ---
        let diabetesEp = Episode(
            title: "Diabetes Management",
            episodeType: .chronic,
            doctorName: "Dr. Anil Kumar",
            diagnosis: "Type 2 Diabetes Mellitus + Hypertension + Hypothyroid"
        )
        diabetesEp.status = .active
        diabetesEp.startDate = cal.date(byAdding: .year, value: -2, to: now) ?? now
        diabetesEp.profile = mom
        mom.episodes.append(diabetesEp)

        let glycomet = makeMedicine(
            brand: "Glycomet GP 2", generic: "Metformin + Glimepiride",
            dosage: "500mg/2mg", freq: .twiceDaily, timing: [.morning, .evening],
            duration: nil, source: .manual, confidence: 1.0,
            instructions: "With meals", manufacturer: "USV", mrp: 185,
            episode: diabetesEp
        )
        let telma = makeMedicine(
            brand: "Telma 40", generic: "Telmisartan",
            dosage: "40mg", freq: .onceDaily, timing: [.morning],
            duration: nil, source: .manual, confidence: 1.0,
            instructions: "Empty stomach", manufacturer: "Glenmark", mrp: 135,
            episode: diabetesEp
        )
        let thyronorm = makeMedicine(
            brand: "Thyronorm 50", generic: "Levothyroxine",
            dosage: "50mcg", freq: .onceDaily, timing: [.morning],
            duration: nil, source: .manual, confidence: 1.0,
            instructions: "30 min before breakfast on empty stomach", manufacturer: "Abbott", mrp: 112,
            episode: diabetesEp
        )

        for med in [glycomet, telma, thyronorm] {
            createDoseLogsWithAdherence(for: med, days: 7, adherenceRate: 0.90)
        }

        addSeedTask("HbA1c Test (quarterly)", type: .labTest, daysFromNow: 10, episode: diabetesEp)
        addSeedTask("Fasting blood sugar check", type: .labTest, daysFromNow: 1, episode: diabetesEp)
        addSeedTask("Endocrinologist follow-up", type: .followUp, daysFromNow: 15, episode: diabetesEp)
        addSeedTask("Eye check-up (annual)", type: .followUp, daysFromNow: 30, episode: diabetesEp)

        addSeedDoc(.labReport, title: "HbA1c Report — Feb 2026", notes: "HbA1c: 7.2% — slightly above target of 7.0%", episode: diabetesEp)
        addSeedDoc(.labReport, title: "Fasting Blood Sugar", notes: "FBS: 142 mg/dL (target < 130)", episode: diabetesEp)
        addSeedDoc(.labReport, title: "Thyroid Profile", notes: "TSH: 3.8 mIU/L — within normal range on current dose", episode: diabetesEp)
        addSeedDoc(.prescription, title: "Dr. Anil's Prescription — Jan 2026", notes: "Glycomet GP 2, Telma 40, Thyronorm 50 — continue same doses", episode: diabetesEp)
        addSeedDoc(.insuranceDoc, title: "Star Health Insurance Card", notes: "Policy #SH2025-12345, Family floater, valid until Dec 2026", episode: diabetesEp)
        addSeedDoc(.bill, title: "Medplus Pharmacy Bill", notes: "Monthly medicines — Rs. 432 total", episode: diabetesEp)
        addSeedDoc(.doctorNote, title: "Dietician Notes", notes: "1500 kcal diabetic diet plan, low GI foods, 30 min walk daily", episode: diabetesEp)

        // ──────────────────────────────────────────────
        // MARK: Profile 3 — Dad (Parent, 62M)
        // ──────────────────────────────────────────────
        let dad = UserProfile(
            name: "Dad",
            relation: .parent,
            dateOfBirth: cal.date(byAdding: .year, value: -62, to: now),
            gender: .male,
            avatarEmoji: "👴"
        )
        dad.user = user
        dad.isActive = false
        dad.bloodGroup = "A+"
        dad.knownConditions = ["Coronary Artery Disease", "Post-CABG"]
        user.profiles.append(dad)

        // --- Episode: Post-CABG Recovery ---
        let cabgEp = Episode(
            title: "Post-CABG Recovery",
            episodeType: .postDischarge,
            doctorName: "Dr. Rajesh Sharma",
            diagnosis: "Triple Vessel CAD — Post CABG (3 grafts)"
        )
        cabgEp.status = .active
        cabgEp.startDate = cal.date(byAdding: .month, value: -1, to: now) ?? now
        cabgEp.profile = dad
        dad.episodes.append(cabgEp)

        let ecosprin = makeMedicine(
            brand: "Ecosprin 75", generic: "Aspirin",
            dosage: "75mg", freq: .onceDaily, timing: [.afternoon],
            duration: nil, source: .manual, confidence: 1.0,
            instructions: "After lunch", manufacturer: "USV", mrp: 35,
            episode: cabgEp
        )
        let clopilet = makeMedicine(
            brand: "Clopilet 75", generic: "Clopidogrel",
            dosage: "75mg", freq: .onceDaily, timing: [.morning],
            duration: nil, source: .manual, confidence: 1.0,
            instructions: "After breakfast", manufacturer: "Sun Pharma", mrp: 92,
            episode: cabgEp
        )
        let atorva = makeMedicine(
            brand: "Atorva 40", generic: "Atorvastatin",
            dosage: "40mg", freq: .onceDaily, timing: [.night],
            duration: nil, source: .manual, confidence: 1.0,
            instructions: "After dinner", manufacturer: "Zydus", mrp: 178,
            episode: cabgEp
        )
        let metXL = makeMedicine(
            brand: "Met XL 25", generic: "Metoprolol Succinate",
            dosage: "25mg", freq: .onceDaily, timing: [.morning],
            duration: nil, source: .manual, confidence: 1.0,
            instructions: "With breakfast", manufacturer: "Cipla", mrp: 85,
            episode: cabgEp
        )
        let cardace = makeMedicine(
            brand: "Cardace 2.5", generic: "Ramipril",
            dosage: "2.5mg", freq: .onceDaily, timing: [.morning],
            duration: nil, source: .manual, confidence: 1.0,
            instructions: "Empty stomach in the morning", manufacturer: "Sanofi", mrp: 62,
            episode: cabgEp
        )

        for med in [ecosprin, clopilet, atorva, metXL, cardace] {
            createDoseLogsWithAdherence(for: med, days: 7, adherenceRate: 1.0)
        }

        addSeedTask("Cardiac rehab session (Week 4)", type: .followUp, daysFromNow: 2, episode: cabgEp)
        addSeedTask("Wound dressing change", type: .lifestyle, daysFromNow: 1, episode: cabgEp)
        addSeedTask("Lipid profile test", type: .labTest, daysFromNow: 7, episode: cabgEp)
        addSeedTask("Follow-up with Dr. Rajesh", type: .followUp, daysFromNow: 14, episode: cabgEp)
        addSeedTask("2D Echo (3-month post-op)", type: .labTest, daysFromNow: 60, episode: cabgEp)

        addSeedDoc(.discharge, title: "CABG Discharge Summary", notes: "Triple CABG (LIMA-LAD, SVG-RCA, SVG-OM), uneventful post-op recovery, discharged day 7", episode: cabgEp)
        addSeedDoc(.scan, title: "Coronary Angiography Report", notes: "Triple vessel disease — LAD 90%, RCA 85%, LCx 70% stenosis", episode: cabgEp)
        addSeedDoc(.scan, title: "2D Echo — Pre-op", notes: "LVEF 50%, mild MR, no RWMA, normal chamber dimensions", episode: cabgEp)
        addSeedDoc(.prescription, title: "Discharge Medicines", notes: "Ecosprin, Clopilet, Atorva 40, Met XL, Cardace — lifelong cardiac regimen", episode: cabgEp)
        addSeedDoc(.bill, title: "Medanta Hospital Bill", notes: "CABG surgery + 7-day ICU stay — Rs. 4,85,000 (insurance settled Rs. 4,00,000)", episode: cabgEp)
        addSeedDoc(.insuranceDoc, title: "HDFC Ergo Claim", notes: "Claim #HE-2026-8812, Rs. 4,00,000 settled, Rs. 85,000 co-pay", episode: cabgEp)
        addSeedDoc(.doctorNote, title: "Wound Care Instructions", notes: "Keep sternotomy incision dry, no heavy lifting 8 weeks, report any redness or discharge", episode: cabgEp)
        addSeedDoc(.other, title: "Cardiac Rehab Plan", notes: "Phase 2 rehab — 12-week graded exercise program, walk 30 min daily, stair climbing week 6", episode: cabgEp)

        save()
        return user
    }

    // MARK: - Seed Helpers

    private func makeMedicine(
        brand: String, generic: String? = nil, dosage: String,
        freq: MedicineFrequency, timing: [MedicineTiming], duration: Int?,
        source: MedicineSource, confidence: Double,
        instructions: String?, manufacturer: String?, mrp: Double?,
        episode: Episode
    ) -> Medicine {
        let med = Medicine(
            brandName: brand, genericName: generic, dosage: dosage,
            frequency: freq, timing: timing, duration: duration,
            source: source, confidenceScore: confidence
        )
        med.instructions = instructions
        med.manufacturer = manufacturer
        if let mrp { med.mrp = mrp }
        med.episode = episode
        episode.medicines.append(med)
        modelContext.insert(med)
        return med
    }

    private func createDoseLogsWithAdherence(for medicine: Medicine, days: Int, adherenceRate: Double) {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday) else { continue }

            for time in medicine.timing {
                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = time.hour
                components.minute = time.minute

                guard let scheduledTime = calendar.date(from: components) else { continue }

                let log = DoseLog(scheduledTime: scheduledTime)
                log.medicine = medicine
                medicine.doseLogs.append(log)
                modelContext.insert(log)

                // For past doses, simulate adherence
                if scheduledTime < Date() {
                    let taken = Double.random(in: 0...1) < adherenceRate
                    if taken {
                        log.markTaken()
                    } else {
                        log.markSkipped(reason: "Forgot")
                    }
                }
            }
        }
        save()
    }

    private func addSeedTask(_ title: String, type: CareTaskType, daysFromNow: Int, episode: Episode, completed: Bool = false) {
        let task = CareTask(
            title: title,
            taskType: type,
            dueDate: Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date())
        )
        task.isCompleted = completed
        task.episode = episode
        episode.tasks.append(task)
        modelContext.insert(task)
    }

    private func addSeedDoc(_ type: ImageType, title: String, notes: String, episode: Episode) {
        let doc = EpisodeImage(imageType: type, title: title)
        doc.notes = notes
        doc.episode = episode
        episode.images.append(doc)
        modelContext.insert(doc)
    }

    // MARK: - Persistence

    func save() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save: \(error)")
        }
    }
}
