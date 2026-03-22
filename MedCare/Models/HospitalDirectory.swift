import Foundation

struct HospitalInfo: Identifiable {
    let id: String
    let name: String
    let city: String
    let state: String
    let type: String
    let specialties: [String]
    let logoEmoji: String
    let specialtyCount: Int
    let doctorCount: Int
}

enum HospitalDirectory {
    static let hospitals: [HospitalInfo] = [
        HospitalInfo(
            id: "apollo-chennai", name: "Apollo Hospitals", city: "Chennai", state: "Tamil Nadu",
            type: "Hospital", specialties: ["Cardiology", "Oncology", "Neurology", "Orthopedics"],
            logoEmoji: "🏥", specialtyCount: 52, doctorCount: 340
        ),
        HospitalInfo(
            id: "fortis-gurugram", name: "Fortis Healthcare", city: "Gurugram", state: "Haryana",
            type: "Hospital", specialties: ["Cardiology", "Nephrology", "Gastroenterology"],
            logoEmoji: "🏥", specialtyCount: 38, doctorCount: 220
        ),
        HospitalInfo(
            id: "max-delhi", name: "Max Healthcare", city: "Delhi", state: "Delhi",
            type: "Hospital", specialties: ["General Medicine", "Cardiology", "Oncology"],
            logoEmoji: "🏥", specialtyCount: 35, doctorCount: 280
        ),
        HospitalInfo(
            id: "medanta-gurugram", name: "Medanta - The Medicity", city: "Gurugram", state: "Haryana",
            type: "Hospital", specialties: ["Cardiology", "Neurology", "Liver Transplant"],
            logoEmoji: "🏥", specialtyCount: 40, doctorCount: 350
        ),
        HospitalInfo(
            id: "aiims-delhi", name: "AIIMS", city: "New Delhi", state: "Delhi",
            type: "Hospital", specialties: ["General Medicine", "Cardiology", "Neurology", "Psychiatry"],
            logoEmoji: "🏛️", specialtyCount: 60, doctorCount: 500
        ),
        HospitalInfo(
            id: "kokilaben-mumbai", name: "Kokilaben Dhirubhai Ambani Hospital", city: "Mumbai", state: "Maharashtra",
            type: "Hospital", specialties: ["Oncology", "Cardiology", "Neurosurgery"],
            logoEmoji: "🏥", specialtyCount: 42, doctorCount: 260
        ),
        HospitalInfo(
            id: "narayana-bangalore", name: "Narayana Health", city: "Bangalore", state: "Karnataka",
            type: "Hospital", specialties: ["Cardiology", "Cardiac Surgery", "Pediatrics"],
            logoEmoji: "🏥", specialtyCount: 30, doctorCount: 180
        ),
        HospitalInfo(
            id: "manipal-bangalore", name: "Manipal Hospitals", city: "Bangalore", state: "Karnataka",
            type: "Hospital", specialties: ["General Medicine", "Orthopedics", "Oncology"],
            logoEmoji: "🏥", specialtyCount: 36, doctorCount: 240
        ),
        HospitalInfo(
            id: "ruby-hall-pune", name: "Ruby Hall Clinic", city: "Pune", state: "Maharashtra",
            type: "Clinic", specialties: ["General Medicine", "Cardiology", "ENT"],
            logoEmoji: "🏥", specialtyCount: 28, doctorCount: 150
        ),
        HospitalInfo(
            id: "cmc-vellore", name: "CMC Vellore", city: "Vellore", state: "Tamil Nadu",
            type: "Hospital", specialties: ["General Medicine", "Nephrology", "Hematology"],
            logoEmoji: "🏛️", specialtyCount: 48, doctorCount: 400
        ),
        HospitalInfo(
            id: "tata-memorial-mumbai", name: "Tata Memorial Hospital", city: "Mumbai", state: "Maharashtra",
            type: "Hospital", specialties: ["Oncology", "Radiation Oncology", "Surgical Oncology"],
            logoEmoji: "🏛️", specialtyCount: 15, doctorCount: 180
        ),
        HospitalInfo(
            id: "lilavati-mumbai", name: "Lilavati Hospital", city: "Mumbai", state: "Maharashtra",
            type: "Hospital", specialties: ["General Medicine", "Cardiology", "Neurology"],
            logoEmoji: "🏥", specialtyCount: 32, doctorCount: 200
        ),
        HospitalInfo(
            id: "sir-ganga-ram-delhi", name: "Sir Ganga Ram Hospital", city: "New Delhi", state: "Delhi",
            type: "Hospital", specialties: ["General Medicine", "Gastroenterology", "Nephrology"],
            logoEmoji: "🏛️", specialtyCount: 38, doctorCount: 250
        ),
        HospitalInfo(
            id: "sankara-nethralaya-chennai", name: "Sankara Nethralaya", city: "Chennai", state: "Tamil Nadu",
            type: "Hospital", specialties: ["Ophthalmology"],
            logoEmoji: "👁️", specialtyCount: 8, doctorCount: 90
        ),
        HospitalInfo(
            id: "care-hyderabad", name: "CARE Hospitals", city: "Hyderabad", state: "Telangana",
            type: "Hospital", specialties: ["Cardiology", "Neurology", "Orthopedics"],
            logoEmoji: "🏥", specialtyCount: 30, doctorCount: 170
        ),
        HospitalInfo(
            id: "hinduja-mumbai", name: "P.D. Hinduja Hospital", city: "Mumbai", state: "Maharashtra",
            type: "Hospital", specialties: ["General Medicine", "Cardiology", "Urology"],
            logoEmoji: "🏥", specialtyCount: 34, doctorCount: 190
        ),
        HospitalInfo(
            id: "aster-kochi", name: "Aster Medcity", city: "Kochi", state: "Kerala",
            type: "Hospital", specialties: ["Cardiology", "Neurology", "Gastroenterology"],
            logoEmoji: "🏥", specialtyCount: 28, doctorCount: 160
        ),
        HospitalInfo(
            id: "pgimer-chandigarh", name: "PGIMER", city: "Chandigarh", state: "Chandigarh",
            type: "Hospital", specialties: ["General Medicine", "Hepatology", "Nephrology"],
            logoEmoji: "🏛️", specialtyCount: 45, doctorCount: 380
        ),
        HospitalInfo(
            id: "jaslok-mumbai", name: "Jaslok Hospital", city: "Mumbai", state: "Maharashtra",
            type: "Hospital", specialties: ["General Medicine", "Cardiology", "Dermatology"],
            logoEmoji: "🏥", specialtyCount: 30, doctorCount: 170
        ),
        HospitalInfo(
            id: "blk-delhi", name: "BLK-Max Super Speciality Hospital", city: "New Delhi", state: "Delhi",
            type: "Hospital", specialties: ["Oncology", "Bone Marrow Transplant", "Cardiology"],
            logoEmoji: "🏥", specialtyCount: 35, doctorCount: 210
        ),
    ]
}
