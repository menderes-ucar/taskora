import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const encoder = new TextEncoder();

function requireEnv(name: string): string {
  const value = Deno.env.get(name);

  if (!value) {
    throw new Error(
      `Missing environment variable: ${name}`,
    );
  }

  return value;
}

function hex(bytes: Uint8Array): string {
  return Array.from(bytes)
    .map((b) =>
      b.toString(16).padStart(2, '0'),
    )
    .join('');
}

function timingSafeEqual(
  a: string,
  b: string,
): boolean {
  if (a.length !== b.length) {
    return false;
  }

  let result = 0;

  for (let i = 0; i < a.length; i++) {
    result |=
        a.charCodeAt(i) ^
        b.charCodeAt(i);
  }

  return result === 0;
}

async function verifyStripeSignature(
  payload: string,
  signature: string,
  secret: string,
): Promise<boolean> {
  const parts = signature.split(',');

  const timestamp =
      parts
          .find((part) =>
            part.startsWith('t='),
          )
          ?.slice(2);

  const signatures =
      parts
          .filter((part) =>
            part.startsWith('v1='),
          )
          .map((part) =>
            part.slice(3),
          );

  if (
    !timestamp ||
    signatures.length === 0
  ) {
    return false;
  }

  const timestampNumber =
      Number(timestamp);

  if (
    !Number.isFinite(
      timestampNumber,
    )
  ) {
    return false;
  }

  const age = Math.abs(
    Math.floor(
      Date.now() / 1000,
    ) - timestampNumber,
  );

  if (age > 300) {
    return false;
  }

  const key =
      await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    {
      name: 'HMAC',
      hash: 'SHA-256',
    },
    false,
    ['sign'],
  );

  const signedPayload =
      `${timestamp}.${payload}`;

  const digest =
      await crypto.subtle.sign(
    'HMAC',
    key,
    encoder.encode(
      signedPayload,
    ),
  );

  const expected =
      hex(
        new Uint8Array(digest),
      );

  return signatures.some(
    (candidate) =>
        timingSafeEqual(
          candidate,
          expected,
        ),
  );
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response(
      'Method Not Allowed',
      { status: 405 },
    );
  }

  try {
    const signature =
        req.headers.get(
          'Stripe-Signature',
        );

    if (!signature) {
      return new Response(
        'Missing Stripe-Signature',
        { status: 400 },
      );
    }

    const payload =
        await req.text();

    const webhookSecret =
        requireEnv(
          'STRIPE_WEBHOOK_SECRET',
        );

    const valid =
        await verifyStripeSignature(
          payload,
          signature,
          webhookSecret,
        );

    if (!valid) {
      return new Response(
        'Invalid signature',
        { status: 400 },
      );
    }

    const event =
        JSON.parse(payload);

    const serviceRoleKey =
        requireEnv(
          'SUPABASE_SERVICE_ROLE_KEY',
        );

    const supabaseUrl =
        requireEnv(
          'SUPABASE_URL',
        );

    const admin =
        createClient(
          supabaseUrl,
          serviceRoleKey,
          {
            auth: {
              persistSession: false,
              autoRefreshToken: false,
            },
          },
        );

    if (
      event.type ===
      'payment_intent.succeeded'
    ) {
      const paymentIntent =
          event.data?.object;

      const paymentIntentId =
          paymentIntent?.id?.toString();

      const amountReceived =
          Number(
            paymentIntent?.amount_received ??
                paymentIntent?.amount,
          );

      const currency =
          paymentIntent?.currency
              ?.toString()
              ?.toLowerCase();

      if (
        !paymentIntentId ||
        !Number.isInteger(
          amountReceived,
        ) ||
        amountReceived <= 0 ||
        !currency
      ) {
        return new Response(
          'Invalid payment intent payload',
          { status: 400 },
        );
      }

      const {
        data,
        error,
      } = await admin.rpc(
        'settle_wallet_topup_from_stripe',
        {
          p_payment_intent_id:
              paymentIntentId,
          p_amount_minor:
              amountReceived,
          p_currency:
              currency,
        },
      );

      if (error) {
        console.error(
          '[stripe-webhook] settlement failed',
          error,
        );

        return new Response(
          'Settlement failed',
          { status: 500 },
        );
      }

      console.log(
        '[stripe-webhook] settlement',
        data,
      );
    }

    if (
      event.type ===
          'payment_intent.payment_failed' ||
      event.type ===
          'payment_intent.canceled'
    ) {
      const paymentIntent =
          event.data?.object;

      const paymentIntentId =
          paymentIntent?.id?.toString();

      if (paymentIntentId) {
        await admin
            .from(
              'wallet_topup_payments',
            )
            .update({
              status:
                  event.type ===
                      'payment_intent.canceled'
                      ? 'cancelled'
                      : 'failed',
              failure_code:
                  paymentIntent
                      ?.last_payment_error
                      ?.code ??
                  null,
              failure_message:
                  paymentIntent
                      ?.last_payment_error
                      ?.message ??
                  null,
            })
            .eq(
              'stripe_payment_intent_id',
              paymentIntentId,
            )
            .neq(
              'status',
              'succeeded',
            );
      }
    }

    return new Response(
      JSON.stringify({
        received: true,
      }),
      {
        status: 200,
        headers: {
          'Content-Type':
              'application/json',
        },
      },
    );
  } catch (error) {
    console.error(
      '[stripe-webhook]',
      error,
    );

    return new Response(
      'Webhook processing failed',
      { status: 500 },
    );
  }
});