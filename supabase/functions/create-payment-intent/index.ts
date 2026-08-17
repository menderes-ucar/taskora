import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-idempotency-key',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });

function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`Missing environment variable: ${name}`);
  }

  return value;
}

function parseAmountMinor(value: unknown): {
  amountTry: number;
  amountMinor: number;
} {
  const amount = typeof value === 'number' ? value : Number(value);

  if (!Number.isFinite(amount) || amount < 10 || amount > 10000) {
    throw new Error('invalid_amount');
  }

  const amountMinor = Math.round(amount * 100);

  if (
    amountMinor <= 0 ||
    Math.abs(amount * 100 - amountMinor) > 0.000001
  ) {
    throw new Error('invalid_amount');
  }

  return {
    amountTry: amountMinor / 100,
    amountMinor,
  };
}

async function stripeRequest(
  secretKey: string,
  path: string,
  params: URLSearchParams,
  idempotencyKey: string,
) {
  const response = await fetch(
    `https://api.stripe.com/v1/${path}`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${secretKey}`,
        'Content-Type': 'application/x-www-form-urlencoded',
        'Idempotency-Key': idempotencyKey,
      },
      body: params.toString(),
    },
  );

  const data = await response.json();

  if (!response.ok) {
    const message =
        data?.error?.message ?? 'Stripe request failed.';

    throw new Error(message);
  }

  return data;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders,
    });
  }

  if (req.method !== 'POST') {
    return json(
      { error: 'method_not_allowed' },
      405,
    );
  }

  try {
    finalAuth:
    {
      const authHeader =
          req.headers.get('Authorization');

      if (!authHeader?.startsWith('Bearer ')) {
        return json(
          { error: 'not_authenticated' },
          401,
        );
      }

      const supabaseUrl =
          requireEnv('SUPABASE_URL');

      const anonKey =
          requireEnv('SUPABASE_ANON_KEY');

      const serviceRoleKey =
          requireEnv('SUPABASE_SERVICE_ROLE_KEY');

      const stripeSecret =
          requireEnv('STRIPE_SECRET_KEY');

      const userClient = createClient(
        supabaseUrl,
        anonKey,
        {
          global: {
            headers: {
              Authorization: authHeader,
            },
          },
          auth: {
            persistSession: false,
            autoRefreshToken: false,
          },
        },
      );

      const {
        data: { user },
        error: userError,
      } = await userClient.auth.getUser();

      if (userError || !user) {
        return json(
          { error: 'not_authenticated' },
          401,
        );
      }

      const body = await req.json();

      const {
        amountTry,
        amountMinor,
      } = parseAmountMinor(body?.amount);

      const currency =
          String(body?.currency ?? 'try').toLowerCase();

      if (currency !== 'try') {
        return json(
          { error: 'unsupported_currency' },
          400,
        );
      }

      const idempotencyKey = String(
        body?.idempotency_key ??
            req.headers.get('x-idempotency-key') ??
            '',
      ).trim();

      if (
        idempotencyKey.length < 8 ||
        idempotencyKey.length > 128
      ) {
        return json(
          { error: 'invalid_idempotency_key' },
          400,
        );
      }

      const admin = createClient(
        supabaseUrl,
        serviceRoleKey,
        {
          auth: {
            persistSession: false,
            autoRefreshToken: false,
          },
        },
      );

      const { data: existing } = await admin
          .from('wallet_topup_payments')
          .select(
            'id, stripe_payment_intent_id, amount_minor, amount_try, currency, status',
          )
          .eq('user_id', user.id)
          .eq('idempotency_key', idempotencyKey)
          .maybeSingle();

      if (existing) {
        if (
          Number(existing.amount_minor) !== amountMinor ||
          Number(existing.amount_try) !== amountTry ||
          existing.currency !== currency
        ) {
          return json(
            {
              error:
                  'idempotency_key_reused_with_different_amount',
            },
            409,
          );
        }

        const paymentIntentResponse =
            await fetch(
          `https://api.stripe.com/v1/payment_intents/${encodeURIComponent(existing.stripe_payment_intent_id)}`,
          {
            headers: {
              Authorization:
                  `Bearer ${stripeSecret}`,
            },
          },
        );

        const paymentData =
            await paymentIntentResponse.json();

        if (!paymentIntentResponse.ok) {
          throw new Error(
            paymentData?.error?.message ??
                'Stripe request failed.',
          );
        }

        return json({
          payment_intent_id:
              paymentData.id,
          client_secret:
              paymentData.client_secret,
          status:
              paymentData.status,
        });
      }

      const params =
          new URLSearchParams();

      params.set(
        'amount',
        String(amountMinor),
      );

      params.set(
        'currency',
        currency,
      );

      params.set(
        'description',
        'Taskora cüzdan bakiyesi yükleme',
      );

      params.set(
        'automatic_payment_methods[enabled]',
        'true',
      );

      params.set(
        'metadata[user_id]',
        user.id,
      );

      params.set(
        'metadata[amount_try]',
        amountTry.toFixed(2),
      );

      params.set(
        'metadata[currency]',
        currency,
      );

      params.set(
        'metadata[idempotency_key]',
        idempotencyKey,
      );

      const stripeIdempotencyKey =
          `taskora-topup-${user.id}-${idempotencyKey}`;

      const paymentIntent =
          await stripeRequest(
        stripeSecret,
        'payment_intents',
        params,
        stripeIdempotencyKey,
      );

      const { error: insertError } =
          await admin
              .from('wallet_topup_payments')
              .insert({
                user_id: user.id,
                idempotency_key:
                    idempotencyKey,
                stripe_payment_intent_id:
                    paymentIntent.id,
                amount_minor:
                    amountMinor,
                amount_try:
                    amountTry,
                currency,
                status: 'pending',
                metadata: {
                  source:
                      'stripe_payment_sheet',
                },
              });

      if (insertError) {
        const { data: canonical } =
            await admin
                .from('wallet_topup_payments')
                .select(
                  'stripe_payment_intent_id',
                )
                .eq(
                  'user_id',
                  user.id,
                )
                .eq(
                  'idempotency_key',
                  idempotencyKey,
                )
                .maybeSingle();

        if (!canonical) {
          throw insertError;
        }
      }

      return json({
        payment_intent_id:
            paymentIntent.id,
        client_secret:
            paymentIntent.client_secret,
        status:
            paymentIntent.status,
      });
    }
  } catch (error) {
    console.error(
      '[create-payment-intent]',
      error,
    );

    const message =
        error instanceof Error
            ? error.message
            : String(error);

    const status =
        message === 'not_authenticated'
            ? 401
            : 400;

    return json(
      { error: message },
      status,
    );
  }
});