import crypto from 'crypto';

// ============================================================
// Razorpay Payment Service
// Handles order creation, subscription management, and QR codes
// ============================================================

interface RazorpayConfig {
  keyId: string;
  keySecret: string;
  baseUrl: string;
}

interface RazorpayOrder {
  id: string;
  amount: number;
  currency: string;
  receipt: string;
  status: string;
}

interface RazorpaySubscription {
  id: string;
  planId: string;
  customerId: string;
  status: string;
  shortUrl: string;
}

interface RazorpayQRCode {
  id: string;
  imageUrl: string;
  amount: number;
  description: string;
  status: string;
}

class RazorpayService {
  private config: RazorpayConfig;

  constructor() {
    this.config = {
      keyId: process.env.RAZORPAY_KEY_ID || '',
      keySecret: process.env.RAZORPAY_KEY_SECRET || '',
      baseUrl: 'https://api.razorpay.com/v1',
    };
  }

  // ============================================================
  // Internal — authenticated fetch to Razorpay API
  // ============================================================

  private async razorpayRequest<T>(method: string, path: string, body?: unknown): Promise<T> {
    const auth = Buffer.from(`${this.config.keyId}:${this.config.keySecret}`).toString('base64');

    const response = await fetch(`${this.config.baseUrl}${path}`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Basic ${auth}`,
      },
      body: body ? JSON.stringify(body) : undefined,
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({}));
      throw new Error(`Razorpay API error: ${response.status} — ${JSON.stringify(error)}`);
    }

    return response.json() as Promise<T>;
  }

  // ============================================================
  // Create Order — used for one-time payments
  // ============================================================

  async createOrder(amount: number, currency: string = 'INR', receipt?: string): Promise<RazorpayOrder> {
    const amountInPaise = Math.round(amount * 100);

    const order = await this.razorpayRequest<RazorpayOrder>('POST', '/orders', {
      amount: amountInPaise,
      currency,
      receipt: receipt || `rcpt_${Date.now()}`,
      payment_capture: 1, // Auto-capture
    });

    return {
      id: order.id,
      amount: amountInPaise,
      currency,
      receipt: order.receipt,
      status: order.status,
    };
  }

  // ============================================================
  // Create Subscription — recurring billing via Razorpay plans
  // ============================================================

  async createSubscription(planId: string, customerId?: string): Promise<RazorpaySubscription> {
    const payload: Record<string, unknown> = {
      plan_id: planId,
      total_count: 12, // 12 billing cycles
      quantity: 1,
    };

    if (customerId) {
      payload.customer_id = customerId;
    }

    const subscription = await this.razorpayRequest<{
      id: string;
      plan_id: string;
      customer_id: string;
      status: string;
      short_url: string;
    }>('POST', '/subscriptions', payload);

    return {
      id: subscription.id,
      planId: subscription.plan_id,
      customerId: subscription.customer_id,
      status: subscription.status,
      shortUrl: subscription.short_url,
    };
  }

  // ============================================================
  // Cancel Subscription
  // ============================================================

  async cancelSubscription(subscriptionId: string, cancelAtCycleEnd: boolean = true): Promise<{ status: string }> {
    const result = await this.razorpayRequest<{ status: string }>(
      'POST',
      `/subscriptions/${subscriptionId}/cancel`,
      { cancel_at_cycle_end: cancelAtCycleEnd ? 1 : 0 }
    );

    return { status: result.status };
  }

  // ============================================================
  // Verify Payment Signature — HMAC-SHA256 verification
  // ============================================================

  verifyPaymentSignature(orderId: string, paymentId: string, signature: string): boolean {
    const payload = `${orderId}|${paymentId}`;
    const expectedSignature = crypto
      .createHmac('sha256', this.config.keySecret)
      .update(payload)
      .digest('hex');

    return expectedSignature === signature;
  }

  // ============================================================
  // Generate QR Code — for in-clinic UPI payments
  // ============================================================

  async generateQRCode(amount: number, description: string): Promise<RazorpayQRCode> {
    const amountInPaise = Math.round(amount * 100);

    const qr = await this.razorpayRequest<{
      id: string;
      image_url: string;
      status: string;
    }>('POST', '/payments/qr_codes', {
      type: 'upi_qr',
      name: 'MedCare Payment',
      usage: 'single_use',
      fixed_amount: true,
      payment_amount: amountInPaise,
      description,
      close_by: Math.floor(Date.now() / 1000) + 30 * 60, // 30 min expiry
    });

    return {
      id: qr.id,
      imageUrl: qr.image_url,
      amount: amountInPaise,
      description,
      status: qr.status,
    };
  }

  // ============================================================
  // Fetch Payment Details
  // ============================================================

  async getPayment(paymentId: string): Promise<Record<string, unknown>> {
    return this.razorpayRequest('GET', `/payments/${paymentId}`);
  }

  // ============================================================
  // List Payments for an Order
  // ============================================================

  async getOrderPayments(orderId: string): Promise<{ items: Record<string, unknown>[] }> {
    return this.razorpayRequest('GET', `/orders/${orderId}/payments`);
  }
}

export const razorpayService = new RazorpayService();
export default razorpayService;
