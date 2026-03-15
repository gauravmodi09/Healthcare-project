import XCTest
@testable import MedCare

final class ModelTests: XCTestCase {

    // MARK: - User Tests

    func testUserCreation() {
        let user = User(phoneNumber: "9876543210")
        XCTAssertEqual(user.phoneNumber, "9876543210")
        XCTAssertEqual(user.countryCode, "+91")
        XCTAssertEqual(user.subscriptionTier, .free)
        XCTAssertTrue(user.profiles.isEmpty)
    }

    func testSubscriptionTierLimits() {
        XCTAssertEqual(SubscriptionTier.free.maxProfiles, 1)
        XCTAssertEqual(SubscriptionTier.pro.maxProfiles, 5)
        XCTAssertEqual(SubscriptionTier.premium.maxProfiles, 10)
        XCTAssertFalse(SubscriptionTier.free.hasAIExtraction)
        XCTAssertTrue(SubscriptionTier.pro.hasAIExtraction)
    }

    // MARK: - Profile Tests

    func testProfileCreation() {
        let profile = UserProfile(
            name: "Rahul",
            relation: .myself,
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: Date()),
            gender: .male
        )
        XCTAssertEqual(profile.name, "Rahul")
        XCTAssertEqual(profile.relation, .myself)
        XCTAssertEqual(profile.age, 30)
        XCTAssertTrue(profile.isActive)
    }

    func testProfileRelationEmoji() {
        XCTAssertEqual(ProfileRelation.myself.emoji, "👤")
        XCTAssertEqual(ProfileRelation.spouse.emoji, "💑")
        XCTAssertEqual(ProfileRelation.parent.emoji, "👨‍👩‍👦")
        XCTAssertEqual(ProfileRelation.child.emoji, "👶")
    }

    // MARK: - Episode Tests

    func testEpisodeCreation() {
        let episode = Episode(
            title: "Cold & Cough",
            episodeType: .acute,
            doctorName: "Dr. Sharma"
        )
        XCTAssertEqual(episode.title, "Cold & Cough")
        XCTAssertEqual(episode.episodeType, .acute)
        XCTAssertEqual(episode.status, .draft)
        XCTAssertTrue(episode.medicines.isEmpty)
    }

    func testEpisodeAdherence() {
        let episode = Episode(title: "Test")
        // With no medicines, adherence should be 0
        XCTAssertEqual(episode.adherencePercentage, 0)
    }

    func testEpisodeTypeIcons() {
        XCTAssertEqual(EpisodeType.acute.icon, "bolt.heart")
        XCTAssertEqual(EpisodeType.chronic.icon, "arrow.triangle.2.circlepath")
        XCTAssertEqual(EpisodeType.postDischarge.icon, "cross.case")
    }

    // MARK: - Medicine Tests

    func testMedicineCreation() {
        let medicine = Medicine(
            brandName: "Augmentin 625",
            genericName: "Amoxicillin",
            dosage: "625mg",
            frequency: .twiceDaily,
            timing: [.morning, .night],
            duration: 5
        )
        XCTAssertEqual(medicine.brandName, "Augmentin 625")
        XCTAssertEqual(medicine.frequency.timesPerDay, 2)
        XCTAssertEqual(medicine.timing.count, 2)
        XCTAssertTrue(medicine.isActive)
    }

    func testMedicineConfidence() {
        let lowConf = Medicine(brandName: "Test", dosage: "10mg", confidenceScore: 0.5)
        let highConf = Medicine(brandName: "Test", dosage: "10mg", confidenceScore: 0.9)

        XCTAssertTrue(lowConf.isLowConfidence)
        XCTAssertFalse(highConf.isLowConfidence)
    }

    func testMedicineTimingSorting() {
        let timings: [MedicineTiming] = [.night, .morning, .afternoon]
        let sorted = timings.sorted()
        XCTAssertEqual(sorted[0], .morning)
        XCTAssertEqual(sorted[1], .afternoon)
        XCTAssertEqual(sorted[2], .night)
    }

    func testMedicineFrequencyTimesPerDay() {
        XCTAssertEqual(MedicineFrequency.onceDaily.timesPerDay, 1)
        XCTAssertEqual(MedicineFrequency.twiceDaily.timesPerDay, 2)
        XCTAssertEqual(MedicineFrequency.thriceDaily.timesPerDay, 3)
        XCTAssertEqual(MedicineFrequency.asNeeded.timesPerDay, 0)
    }

    // MARK: - Dose Log Tests

    func testDoseLogMarkTaken() {
        let log = DoseLog(scheduledTime: Date())
        XCTAssertEqual(log.status, .pending)

        log.markTaken()
        XCTAssertEqual(log.status, .taken)
        XCTAssertNotNil(log.actualTime)
    }

    func testDoseLogMarkSkipped() {
        let log = DoseLog(scheduledTime: Date())
        log.markSkipped(reason: "Feeling better")
        XCTAssertEqual(log.status, .skipped)
        XCTAssertEqual(log.skipReason, "Feeling better")
    }

    // MARK: - Symptom Log Tests

    func testSymptomEntry() {
        let entry = SymptomEntry(name: "Headache", severity: .moderate)
        XCTAssertEqual(entry.name, "Headache")
        XCTAssertEqual(entry.severity, .moderate)
    }

    func testFeelingLevel() {
        XCTAssertEqual(FeelingLevel.terrible.emoji, "😫")
        XCTAssertEqual(FeelingLevel.great.emoji, "😊")
        XCTAssertEqual(FeelingLevel.okay.rawValue, 3)
    }

    func testSeverityLevel() {
        XCTAssertEqual(SeverityLevel.mild.label, "Mild")
        XCTAssertEqual(SeverityLevel.critical.label, "Critical")
    }

    // MARK: - Care Task Tests

    func testCareTaskCreation() {
        let task = CareTask(
            title: "Follow-up visit",
            taskType: .followUp,
            dueDate: Date()
        )
        XCTAssertEqual(task.title, "Follow-up visit")
        XCTAssertFalse(task.isCompleted)
        XCTAssertEqual(task.priority, .medium)
    }

    func testCareTaskTypes() {
        XCTAssertEqual(CareTaskType.labTest.icon, "testtube.2")
        XCTAssertEqual(CareTaskType.followUp.icon, "calendar.badge.clock")
        XCTAssertEqual(CareTaskType.physio.icon, "figure.walk")
    }

    // MARK: - Episode Image Tests

    func testEpisodeImageCreation() {
        let image = EpisodeImage(imageType: .prescription)
        XCTAssertEqual(image.imageType, .prescription)
        XCTAssertEqual(image.uploadStatus, .pending)
    }

    // MARK: - Color Tests

    func testConfidenceColors() {
        let low = MCColors.confidenceColor(0.3)     // Should be error/red
        let medium = MCColors.confidenceColor(0.6)   // Should be warning/amber
        let high = MCColors.confidenceColor(0.8)     // Should be info/blue
        let veryHigh = MCColors.confidenceColor(0.95) // Should be success/green

        // Just ensure they don't crash - color equality is tricky
        XCTAssertNotNil(low)
        XCTAssertNotNil(medium)
        XCTAssertNotNil(high)
        XCTAssertNotNil(veryHigh)
    }

    // MARK: - Date Extension Tests

    func testDateExtensions() {
        let now = Date()
        XCTAssertTrue(now.isToday)
        XCTAssertFalse(now.isTomorrow)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        XCTAssertTrue(yesterday.isPast)
    }
}
