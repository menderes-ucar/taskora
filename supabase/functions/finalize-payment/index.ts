import Stripe from 'npm:stripe@14.25.0';
import { createClient } from 'npm:@supabase/supabase-js@2.45.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders,
    });
  }

  if (req.method !== 'POST') {
    return jsonResponse(
      {
        success: false,
        message: 'Method not allowed',
      },
      405,
    );
  }

  try {
    const authHeader = req.headers.get('Authorization');

    if (!authHeader) {
      return jsonResponse(
        {
          success: false,
          message: 'Unauthorized',
        },
        401,
      );
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
    const serviceRoleKey =
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    const stripeSecret =
        Deno.env.get('STRIPE_SECRET_KEY');

    if (!supabaseUrl ||
        !supabaseAnonKey ||
        !serviceRoleKey ||
        !stripeSecret) {
      return jsonResponse(
        {
          success: false,
          message: 'Payment service is not configured',
        },
        500,
      );
    }

    final userClient = createClient(
      supabaseUrl,
      supabaseAnonKey,
      {
        global: {
          headers: {
            Authorization: authHeader,
          },
        },
      },
    );

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();

    if (userError || user == null) {
      return jsonResponse(
        {
          success: false,
          message: 'Unauthorized',
        },
        401,
      );
    }

    final body = await req.json();

    final paymentIntentId =
        body['payment_intent_id']?.toString().trim();

    if (paymentIntentId == null ||
        paymentIntentId.isEmpty) {
      return jsonResponse(
        {
          success: false,
          message: 'payment_intent_id is required',
        },
        400,
      );
    }

    final stripe = Stripe(
      stripeSecret,
      apiVersion: '2024-06-20',
      httpClient: Stripe.createFetchHttpClient(),
    );

    final intent =
        await stripe.paymentIntents.retrieve(paymentIntentId);

    if (intent.status != 'succeeded') {
      return jsonResponse(
        {
          'success': false,
          'message':
              'Payment is not settled: ${intent.status}',
        },
        400,
      );
    }

    final metadataUserId =
        intent.metadata?['user_id'];

    final purpose =
        intent.metadata?['purpose'];

    if (metadataUserId != user.id ||
        purpose != 'wallet_topup') {
      return jsonResponse(
        {
          'success': false,
          'message': 'Payment does not belong to this account',
        },
        403,
      );
    }

    final amountTry =
        intent.amount / 100.0;

    if (amountTry <= 0) {
      return jsonResponse(
        {
          'success': false,
          'message': 'Invalid payment amount',
        },
        400,
      );
    }

    final adminClient = createClient(
      supabaseUrl,
      serviceRoleKey,
    );

    final result =
        await adminClient.rpc(
      'credit_wallet_from_payment',
      params: {
        'p_payment_intent_id': intent.id,
        'p_user_id': user.id,
        'p_amount_try': amountTry,
      },
    );

    return jsonResponse({
      'success': true,
      'data': result,
    });
  } catch (error) {
    console.error('finalize-payment error:', error);

    return jsonResponse(
      {
        'success': false,
        'message': 'Payment finalization failed',
      },
      500,
    );
  }
});