import Foundation

/// AI Positioning Agent
/// Analyzes competitive landscape and strengthens MedCare's market positioning
/// This agent continuously evaluates and recommends strategies to defend and
/// extend MedCare's competitive advantages in the Indian health tech market.
///
/// The agent operates on three pillars:
/// 1. DEFEND existing moats (data network, dual-capture IP, regional language AI)
/// 2. EXTEND into adjacent opportunities (pharmacy integration, insurance, wearables)
/// 3. DISRUPT through innovation (voice-first UX, predictive health, community)

@Observable
final class PositioningAgent {

    // MARK: - Competitive Analysis

    struct Competitor {
        let name: String
        let category: CompetitorCategory
        let strengths: [String]
        let weaknesses: [String]
        let marketShare: Double // Estimated India market share %
        let userBase: String // "10L+", "1Cr+", etc.
    }

    enum CompetitorCategory: String {
        case directCompetitor = "Direct Competitor"
        case adjacentPlayer = "Adjacent Player"
        case potentialEntrant = "Potential Entrant"
    }

    let competitiveLandscape: [Competitor] = [
        Competitor(
            name: "Practo",
            category: .adjacentPlayer,
            strengths: ["Doctor network", "Brand awareness", "Teleconsultation"],
            weaknesses: ["No prescription scanning", "No medication reminders", "No adherence tracking"],
            marketShare: 15.0,
            userBase: "5Cr+"
        ),
        Competitor(
            name: "1mg (Tata Health)",
            category: .adjacentPlayer,
            strengths: ["Pharmacy delivery", "Medicine information", "Tata backing"],
            weaknesses: ["No prescription AI extraction", "No dual-capture", "No care plan tracking"],
            marketShare: 12.0,
            userBase: "3Cr+"
        ),
        Competitor(
            name: "PharmEasy",
            category: .adjacentPlayer,
            strengths: ["Medicine delivery", "Large catalog", "Diagnostics"],
            weaknesses: ["No AI extraction", "No adherence engine", "No family tracking"],
            marketShare: 10.0,
            userBase: "2Cr+"
        ),
        Competitor(
            name: "Medisafe",
            category: .directCompetitor,
            strengths: ["Good reminder UX", "International", "Wearable integration"],
            weaknesses: ["Not India-optimized", "No Indian Rx scanning", "No dual-capture", "No regional language support"],
            marketShare: 2.0,
            userBase: "10L+"
        ),
        Competitor(
            name: "MyTherapy",
            category: .directCompetitor,
            strengths: ["Simple UX", "Health diary", "International"],
            weaknesses: ["Not India-optimized", "No AI extraction", "No Indian pharma data"],
            marketShare: 1.0,
            userBase: "5L+"
        ),
    ]

    // MARK: - Strategic Recommendations

    struct StrategicRecommendation: Identifiable {
        let id = UUID()
        let pillar: StrategyPillar
        let title: String
        let description: String
        let effort: EffortLevel
        let impact: ImpactLevel
        let timeline: String
        let metrics: [String]
    }

    enum StrategyPillar: String {
        case defend = "Defend"
        case extend = "Extend"
        case disrupt = "Disrupt"

        var icon: String {
            switch self {
            case .defend: return "shield.checkered"
            case .extend: return "arrow.up.right.circle"
            case .disrupt: return "bolt.circle"
            }
        }

        var color: String {
            switch self {
            case .defend: return "0A7E8C"
            case .extend: return "F5A623"
            case .disrupt: return "FF6B6B"
            }
        }
    }

    enum EffortLevel: String { case low = "Low", medium = "Medium", high = "High" }
    enum ImpactLevel: String { case low = "Low", medium = "Medium", high = "High", critical = "Critical" }

    /// Generate strategic recommendations based on current app state
    func generateRecommendations() -> [StrategicRecommendation] {
        [
            // DEFEND pillar
            StrategicRecommendation(
                pillar: .defend,
                title: "Accelerate Pharma Data Collection",
                description: "Every user scan strengthens the network effect. Incentivize scanning with free Pro days per 5 prescriptions scanned.",
                effort: .low,
                impact: .critical,
                timeline: "Sprint 13",
                metrics: ["Scans/user/month", "Unique medicines in DB", "Avg confidence score"]
            ),
            StrategicRecommendation(
                pillar: .defend,
                title: "Patent Dual-Capture Method",
                description: "File utility patent for the dual-capture cross-referencing method (prescription + packaging photo → confidence scoring). This is novel in India.",
                effort: .medium,
                impact: .critical,
                timeline: "Month 4",
                metrics: ["Patent filed Y/N", "Prior art search clear"]
            ),
            StrategicRecommendation(
                pillar: .defend,
                title: "DPDP Compliance Certification",
                description: "Get certified DPDP compliant before competitors. Trust badge builds user confidence. Most competitors are NOT compliant yet.",
                effort: .high,
                impact: .high,
                timeline: "Month 5-6",
                metrics: ["Certification obtained Y/N", "Trust badge click-through"]
            ),

            // EXTEND pillar
            StrategicRecommendation(
                pillar: .extend,
                title: "Pharmacy Delivery Integration",
                description: "Partner with 1mg/PharmEasy for medicine delivery from within MedCare. When a user's medicine is about to run out, offer one-tap reorder. Revenue: 8-12% commission.",
                effort: .high,
                impact: .high,
                timeline: "v2 (Month 4-6)",
                metrics: ["Orders/user/month", "Reorder conversion rate", "Commission revenue"]
            ),
            StrategicRecommendation(
                pillar: .extend,
                title: "Insurance Integration",
                description: "Partner with Star Health, HDFC Ergo for automatic claim filing. Adherence data proves compliance → lower premiums. Revenue: lead generation fees.",
                effort: .high,
                impact: .high,
                timeline: "v3 (Month 7-9)",
                metrics: ["Claims filed", "Premium reduction achieved", "Partner revenue"]
            ),
            StrategicRecommendation(
                pillar: .extend,
                title: "Doctor Dashboard (B2B)",
                description: "Offer doctors a free dashboard showing their patients' adherence data. Builds doctor loyalty and prescription-to-app referrals. Moat: doctor network.",
                effort: .medium,
                impact: .high,
                timeline: "v2 (Month 4-5)",
                metrics: ["Doctors registered", "Patient referrals from doctors", "Doctor NPS"]
            ),

            // DISRUPT pillar
            StrategicRecommendation(
                pillar: .disrupt,
                title: "Voice-First Medicine Logging",
                description: "'Hey MedCare, I took my morning medicine' — voice logging for elderly users and accessibility. India has 300M+ voice-first users.",
                effort: .medium,
                impact: .high,
                timeline: "v2 (Month 5)",
                metrics: ["Voice logs/day", "Elderly user adoption", "Accessibility score"]
            ),
            StrategicRecommendation(
                pillar: .disrupt,
                title: "Predictive Non-Adherence Alert",
                description: "ML model that predicts when a user is likely to miss a dose (based on patterns: weekends, travel, late nights) and sends preemptive reminders.",
                effort: .high,
                impact: .high,
                timeline: "v2 (Month 6)",
                metrics: ["Prediction accuracy", "Prevented misses", "Adherence improvement %"]
            ),
            StrategicRecommendation(
                pillar: .disrupt,
                title: "Community Health Circles",
                description: "Anonymous support groups for chronic conditions (diabetes, hypertension). Users share tips, motivate each other. Builds emotional switching cost.",
                effort: .medium,
                impact: .medium,
                timeline: "v3 (Month 8)",
                metrics: ["Active circles", "Posts/week", "Retention lift for circle members"]
            ),
            StrategicRecommendation(
                pillar: .disrupt,
                title: "WhatsApp Bot Integration",
                description: "India's #1 messaging app. Let users log doses, get reminders, and check adherence via WhatsApp. Reduces need to open the app. Massive adoption lever.",
                effort: .medium,
                impact: .critical,
                timeline: "v2 (Month 4)",
                metrics: ["WhatsApp active users", "Dose logs via WA", "Acquisition from WA"]
            ),
        ]
    }

    // MARK: - Moat Strength Assessment

    struct MoatAssessment {
        let moatName: String
        let currentStrength: Double // 0-1
        let trend: MoatTrend
        let vulnerabilities: [String]
        let reinforcementActions: [String]
    }

    enum MoatTrend: String {
        case strengthening = "Strengthening"
        case stable = "Stable"
        case weakening = "Weakening"
    }

    func assessMoats() -> [MoatAssessment] {
        [
            MoatAssessment(
                moatName: "Pharma Data Network Effect",
                currentStrength: 0.3, // Early stage, growing
                trend: .strengthening,
                vulnerabilities: [
                    "Could be replicated with sufficient funding",
                    "Dependent on user scan volume"
                ],
                reinforcementActions: [
                    "Incentivize scanning (gamification, free Pro days)",
                    "Partner with pharmacies for bulk data",
                    "File data licensing agreements"
                ]
            ),
            MoatAssessment(
                moatName: "Dual-Capture IP",
                currentStrength: 0.8,
                trend: .stable,
                vulnerabilities: [
                    "Method could be copied without patent",
                    "Dependent on AI accuracy improvements"
                ],
                reinforcementActions: [
                    "File utility patent immediately",
                    "Publish research paper establishing prior art",
                    "Develop 3-way capture (Rx + packaging + billing receipt)"
                ]
            ),
            MoatAssessment(
                moatName: "Regional Language Processing",
                currentStrength: 0.6,
                trend: .strengthening,
                vulnerabilities: [
                    "Large AI companies could build similar",
                    "Regional data collection is slow"
                ],
                reinforcementActions: [
                    "Hire regional language annotators",
                    "Partner with medical colleges in each state",
                    "Build handwriting style database per doctor"
                ]
            ),
            MoatAssessment(
                moatName: "DPDP Compliance (Regulatory)",
                currentStrength: 0.7,
                trend: .strengthening,
                vulnerabilities: [
                    "Competitors will eventually comply too"
                ],
                reinforcementActions: [
                    "Get certified first — first-mover advantage",
                    "Build compliance into brand messaging",
                    "Offer data deletion as a feature, not just compliance"
                ]
            ),
            MoatAssessment(
                moatName: "Family Health Graph",
                currentStrength: 0.4,
                trend: .strengthening,
                vulnerabilities: [
                    "Users may not add family members",
                    "Privacy concerns with family data"
                ],
                reinforcementActions: [
                    "Simplify family onboarding to 2 taps",
                    "Show family adherence dashboard",
                    "Enable family member invites via link"
                ]
            ),
        ]
    }

    // MARK: - App Store Optimization (ASO) Recommendations

    struct ASORecommendation {
        let title: String
        let keywords: [String]
        let subtitle: String
        let description: String
    }

    func generateASOStrategy() -> ASORecommendation {
        ASORecommendation(
            title: "MedCare: Smart Pill Reminder",
            keywords: [
                "medicine reminder", "pill tracker", "prescription scanner",
                "medication reminder", "dose tracker", "health app india",
                "dawai reminder", "medicine alarm", "family health",
                "adherence tracker", "prescription reader", "medical app"
            ],
            subtitle: "AI Prescription Scanner & Medicine Reminder",
            description: """
            MedCare transforms your paper prescriptions into smart, trackable care plans. \
            Simply photograph your prescription and medicine packaging — our AI extracts \
            everything and sets up personalized reminders.

            FEATURES:
            - AI Prescription Scanner (works with handwritten Indian prescriptions)
            - Smart Medicine Reminders with Taken/Skip/Snooze
            - Family Health Management (up to 5 members)
            - Adherence Tracking & Reports for your doctor
            - Drug Interaction Warnings
            - Medicine Expiry Alerts
            - Symptom Diary

            PRIVACY: DPDP Act 2023 compliant. Your health data is encrypted and never shared.
            """
        )
    }
}
