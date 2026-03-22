import axios, { AxiosInstance } from 'axios';
import { v4 as uuid } from 'uuid';

// ============================================================
// ABDM (Ayushman Bharat Digital Mission) Integration Service
// Handles ABHA creation, verification, and FHIR bundle generation
// ============================================================

interface ABDMConfig {
  baseUrl: string;
  clientId: string;
  clientSecret: string;
  accessToken?: string;
}

interface ABHACreationResponse {
  txnId: string;
  message: string;
}

interface ABHAVerifyResponse {
  abhaNumber: string;
  abhaAddress: string;
  name: string;
  mobile: string;
  healthIdNumber: string;
  token: string;
}

interface ABHAProfile {
  abhaNumber: string;
  abhaAddress: string;
  name: string;
  gender: string;
  dateOfBirth: string;
  mobile: string;
  address: string;
  kycVerified: boolean;
}

// FHIR R4 resource interfaces
interface FHIRBundle {
  resourceType: 'Bundle';
  id: string;
  type: 'document' | 'collection';
  timestamp: string;
  entry: FHIRBundleEntry[];
}

interface FHIRBundleEntry {
  fullUrl: string;
  resource: Record<string, unknown>;
}

class ABDMService {
  private client: AxiosInstance;
  private config: ABDMConfig;

  constructor() {
    const isSandbox = process.env.ABDM_ENV !== 'production';

    this.config = {
      baseUrl: isSandbox
        ? 'https://healthidsbx.abdm.gov.in/api'
        : 'https://healthid.abdm.gov.in/api',
      clientId: process.env.ABDM_CLIENT_ID || '',
      clientSecret: process.env.ABDM_CLIENT_SECRET || '',
    };

    this.client = axios.create({
      baseURL: this.config.baseUrl,
      headers: {
        'Content-Type': 'application/json',
      },
      timeout: 30000,
    });
  }

  // ============================================================
  // Authentication — get session token from ABDM gateway
  // ============================================================

  private async getSessionToken(): Promise<string> {
    if (this.config.accessToken) return this.config.accessToken;

    const response = await this.client.post('/v1/auth/cert', {
      clientId: this.config.clientId,
      clientSecret: this.config.clientSecret,
    });

    this.config.accessToken = response.data.accessToken;
    return response.data.accessToken;
  }

  private async authHeaders() {
    const token = await this.getSessionToken();
    return { Authorization: `Bearer ${token}` };
  }

  // ============================================================
  // ABHA Creation via Aadhaar — Step 1: Generate OTP
  // ============================================================

  async createABHAViaAadhaar(aadhaarNumber: string): Promise<ABHACreationResponse> {
    const headers = await this.authHeaders();

    const response = await this.client.post(
      '/v2/registration/aadhaar/generateOtp',
      { aadhaar: aadhaarNumber },
      { headers }
    );

    return {
      txnId: response.data.txnId,
      message: 'OTP sent to Aadhaar-linked mobile',
    };
  }

  // ============================================================
  // ABHA Creation via Aadhaar — Step 2: Verify OTP & create ABHA
  // ============================================================

  async verifyAadhaarOTP(txnId: string, otp: string): Promise<ABHAVerifyResponse> {
    const headers = await this.authHeaders();

    const response = await this.client.post(
      '/v2/registration/aadhaar/verifyOtp',
      { txnId, otp },
      { headers }
    );

    return {
      abhaNumber: response.data.healthIdNumber,
      abhaAddress: response.data.healthId,
      name: response.data.name,
      mobile: response.data.mobile,
      healthIdNumber: response.data.healthIdNumber,
      token: response.data.token,
    };
  }

  // ============================================================
  // ABHA Creation via Mobile
  // ============================================================

  async createABHAViaMobile(mobile: string): Promise<ABHACreationResponse> {
    const headers = await this.authHeaders();

    const response = await this.client.post(
      '/v2/registration/mobile/generateOtp',
      { mobile },
      { headers }
    );

    return {
      txnId: response.data.txnId,
      message: 'OTP sent to mobile number',
    };
  }

  // ============================================================
  // Create PHR Address (@abdm)
  // ============================================================

  async createPHRAddress(abhaNumber: string, address: string): Promise<{ phrAddress: string }> {
    const headers = await this.authHeaders();

    const response = await this.client.post(
      '/v1/phr/registration/hid/create-phr-address',
      {
        healthIdNumber: abhaNumber,
        phrAddress: `${address}@abdm`,
      },
      { headers }
    );

    return { phrAddress: response.data.phrAddress };
  }

  // ============================================================
  // Verify existing ABHA number
  // ============================================================

  async verifyABHA(abhaNumber: string): Promise<ABHAProfile> {
    const headers = await this.authHeaders();

    const response = await this.client.get(
      `/v1/search/searchByHealthId`,
      {
        headers,
        params: { healthId: abhaNumber },
      }
    );

    return {
      abhaNumber: response.data.healthIdNumber,
      abhaAddress: response.data.healthId,
      name: response.data.name,
      gender: response.data.gender,
      dateOfBirth: response.data.dateOfBirth,
      mobile: response.data.mobile,
      address: response.data.address ?? '',
      kycVerified: response.data.kycVerified ?? false,
    };
  }

  // ============================================================
  // Get ABHA Profile
  // ============================================================

  async getProfile(abhaToken: string): Promise<ABHAProfile> {
    const response = await this.client.get('/v1/account/profile', {
      headers: {
        'X-Token': `Bearer ${abhaToken}`,
      },
    });

    return {
      abhaNumber: response.data.healthIdNumber,
      abhaAddress: response.data.healthId,
      name: response.data.name,
      gender: response.data.gender,
      dateOfBirth: response.data.dateOfBirth,
      mobile: response.data.mobile,
      address: response.data.address ?? '',
      kycVerified: response.data.kycVerified ?? false,
    };
  }

  // ============================================================
  // FHIR R4 Bundle Builders
  // ============================================================

  buildPrescriptionBundle(params: {
    patientName: string;
    patientAbhaId: string;
    doctorName: string;
    medications: Array<{
      name: string;
      dosage: string;
      frequency: string;
      duration: string;
    }>;
  }): FHIRBundle {
    const bundleId = uuid();
    const now = new Date().toISOString();
    const patientId = uuid();
    const practitionerId = uuid();

    const entries: FHIRBundleEntry[] = [
      // Patient resource
      {
        fullUrl: `urn:uuid:${patientId}`,
        resource: {
          resourceType: 'Patient',
          id: patientId,
          identifier: [
            {
              system: 'https://healthid.abdm.gov.in',
              value: params.patientAbhaId,
            },
          ],
          name: [{ text: params.patientName }],
        },
      },
      // Practitioner resource
      {
        fullUrl: `urn:uuid:${practitionerId}`,
        resource: {
          resourceType: 'Practitioner',
          id: practitionerId,
          name: [{ text: params.doctorName }],
        },
      },
      // MedicationRequest resources
      ...params.medications.map((med) => {
        const medId = uuid();
        return {
          fullUrl: `urn:uuid:${medId}`,
          resource: {
            resourceType: 'MedicationRequest',
            id: medId,
            status: 'active',
            intent: 'order',
            medicationCodeableConcept: {
              text: med.name,
            },
            subject: { reference: `urn:uuid:${patientId}` },
            requester: { reference: `urn:uuid:${practitionerId}` },
            dosageInstruction: [
              {
                text: `${med.dosage} ${med.frequency} for ${med.duration}`,
                timing: { code: { text: med.frequency } },
                doseAndRate: [{ doseQuantity: { value: 1, unit: med.dosage } }],
              },
            ],
            authoredOn: now,
          },
        };
      }),
    ];

    return {
      resourceType: 'Bundle',
      id: bundleId,
      type: 'document',
      timestamp: now,
      entry: entries,
    };
  }

  buildDiagnosticReportBundle(params: {
    patientName: string;
    patientAbhaId: string;
    reportName: string;
    observations: Array<{
      name: string;
      value: number;
      unit: string;
      referenceRange?: string;
    }>;
  }): FHIRBundle {
    const bundleId = uuid();
    const now = new Date().toISOString();
    const patientId = uuid();
    const reportId = uuid();

    const observationEntries: FHIRBundleEntry[] = params.observations.map((obs) => {
      const obsId = uuid();
      return {
        fullUrl: `urn:uuid:${obsId}`,
        resource: {
          resourceType: 'Observation',
          id: obsId,
          status: 'final',
          code: { text: obs.name },
          subject: { reference: `urn:uuid:${patientId}` },
          valueQuantity: { value: obs.value, unit: obs.unit },
          referenceRange: obs.referenceRange
            ? [{ text: obs.referenceRange }]
            : undefined,
          effectiveDateTime: now,
        },
      };
    });

    const entries: FHIRBundleEntry[] = [
      {
        fullUrl: `urn:uuid:${patientId}`,
        resource: {
          resourceType: 'Patient',
          id: patientId,
          identifier: [
            { system: 'https://healthid.abdm.gov.in', value: params.patientAbhaId },
          ],
          name: [{ text: params.patientName }],
        },
      },
      {
        fullUrl: `urn:uuid:${reportId}`,
        resource: {
          resourceType: 'DiagnosticReport',
          id: reportId,
          status: 'final',
          code: { text: params.reportName },
          subject: { reference: `urn:uuid:${patientId}` },
          result: observationEntries.map((e) => ({
            reference: e.fullUrl,
          })),
          effectiveDateTime: now,
          issued: now,
        },
      },
      ...observationEntries,
    ];

    return {
      resourceType: 'Bundle',
      id: bundleId,
      type: 'document',
      timestamp: now,
      entry: entries,
    };
  }

  buildWellnessRecordBundle(params: {
    patientName: string;
    patientAbhaId: string;
    vitals: Array<{
      type: string; // e.g. "blood-pressure", "heart-rate", "temperature"
      value: number;
      unit: string;
    }>;
  }): FHIRBundle {
    const bundleId = uuid();
    const now = new Date().toISOString();
    const patientId = uuid();

    const vitalCodes: Record<string, { system: string; code: string; display: string }> = {
      'blood-pressure-systolic': { system: 'http://loinc.org', code: '8480-6', display: 'Systolic blood pressure' },
      'blood-pressure-diastolic': { system: 'http://loinc.org', code: '8462-4', display: 'Diastolic blood pressure' },
      'heart-rate': { system: 'http://loinc.org', code: '8867-4', display: 'Heart rate' },
      'temperature': { system: 'http://loinc.org', code: '8310-5', display: 'Body temperature' },
      'spo2': { system: 'http://loinc.org', code: '2708-6', display: 'Oxygen saturation' },
      'weight': { system: 'http://loinc.org', code: '29463-7', display: 'Body weight' },
      'height': { system: 'http://loinc.org', code: '8302-2', display: 'Body height' },
      'blood-glucose': { system: 'http://loinc.org', code: '2339-0', display: 'Blood glucose' },
    };

    const entries: FHIRBundleEntry[] = [
      {
        fullUrl: `urn:uuid:${patientId}`,
        resource: {
          resourceType: 'Patient',
          id: patientId,
          identifier: [
            { system: 'https://healthid.abdm.gov.in', value: params.patientAbhaId },
          ],
          name: [{ text: params.patientName }],
        },
      },
      ...params.vitals.map((vital) => {
        const obsId = uuid();
        const coding = vitalCodes[vital.type];
        return {
          fullUrl: `urn:uuid:${obsId}`,
          resource: {
            resourceType: 'Observation',
            id: obsId,
            status: 'final',
            category: [
              {
                coding: [
                  {
                    system: 'http://terminology.hl7.org/CodeSystem/observation-category',
                    code: 'vital-signs',
                    display: 'Vital Signs',
                  },
                ],
              },
            ],
            code: coding
              ? { coding: [coding], text: coding.display }
              : { text: vital.type },
            subject: { reference: `urn:uuid:${patientId}` },
            valueQuantity: { value: vital.value, unit: vital.unit },
            effectiveDateTime: now,
          },
        };
      }),
    ];

    return {
      resourceType: 'Bundle',
      id: bundleId,
      type: 'collection',
      timestamp: now,
      entry: entries,
    };
  }
}

export const abdmService = new ABDMService();
export default abdmService;
