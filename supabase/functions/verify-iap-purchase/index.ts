import { createClient } from "https://esm.sh/@supabase/supabase-js@2.56.0";
import { SignJWT, importPKCS8 } from "npm:jose@6.0.10";
import {
  Environment,
  SignedDataVerifier,
} from "npm:@apple/app-store-server-library@3.1.0";
import { Buffer } from "node:buffer";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const adminClient = createClient(supabaseUrl, serviceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function getUserId(request: Request): Promise<string> {
  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) throw new Error("unauthorized");

  const token = authorization.substring("Bearer ".length).trim();
  const client = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const { data, error } = await client.auth.getUser(token);
  if (error || !data.user) throw new Error("unauthorized");
  return data.user.id;
}

async function googleAccessToken(): Promise<string> {
  const raw = Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON");
  if (!raw) throw new Error("google_play_not_configured");

  const serviceAccount = JSON.parse(raw);
  const privateKey = await importPKCS8(serviceAccount.private_key, "RS256");
  const now = Math.floor(Date.now() / 1000);

  const assertion = await new SignJWT({
    scope: "https://www.googleapis.com/auth/androidpublisher",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(serviceAccount.client_email)
    .setSubject(serviceAccount.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(privateKey);

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });

  if (!tokenResponse.ok) {
    throw new Error(`google_auth_failed:${await tokenResponse.text()}`);
  }

  const token = await tokenResponse.json();
  return token.access_token;
}

async function verifyGooglePurchase(productId: string, purchaseToken: string) {
  const packageName = Deno.env.get("GOOGLE_PLAY_PACKAGE_NAME");
  if (!packageName) throw new Error("google_play_not_configured");

  const accessToken = await googleAccessToken();
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
    `${encodeURIComponent(packageName)}/purchases/productsv2/tokens/${encodeURIComponent(purchaseToken)}`;

  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (!response.ok) {
    throw new Error(`google_purchase_invalid:${await response.text()}`);
  }

  const purchase = await response.json();
  const lineItems = Array.isArray(purchase.productLineItem)
    ? purchase.productLineItem
    : [];
  const line = lineItems.find((item: Record<string, unknown>) =>
    item.productId === productId,
  );

  if (!line) throw new Error("google_product_mismatch");

  const purchaseState = purchase.purchaseStateContext?.purchaseState;
  if (purchaseState !== "PURCHASED") {
    throw new Error("google_purchase_not_completed");
  }

  const quantity = Number(line.quantity ?? 1);
  if (!Number.isInteger(quantity) || quantity < 1 || quantity > 100) {
    throw new Error("invalid_quantity");
  }

  return {
    transactionId: purchaseToken,
    quantity,
    metadata: purchase,
  };
}

async function verifyApplePurchase(productId: string, signedTransaction: string) {
  const bundleId = Deno.env.get("APPLE_BUNDLE_ID");
  if (!bundleId) throw new Error("apple_not_configured");

  if (signedTransaction.split(".").length !== 3) {
    throw new Error("apple_signed_transaction_required");
  }

  const [g2, g3] = await Promise.all([
    fetch("https://www.apple.com/certificateauthority/AppleRootCA-G2.cer").then((r) => r.arrayBuffer()),
    fetch("https://www.apple.com/certificateauthority/AppleRootCA-G3.cer").then((r) => r.arrayBuffer()),
  ]);

  const environment = Deno.env.get("APPLE_ENVIRONMENT") === "PRODUCTION"
    ? Environment.PRODUCTION
    : Environment.SANDBOX;

  const appAppleId = environment === Environment.PRODUCTION
    ? Number(Deno.env.get("APPLE_APPLE_ID"))
    : undefined;

  if (environment === Environment.PRODUCTION && !Number.isFinite(appAppleId)) {
    throw new Error("apple_app_id_not_configured");
  }

  const verifier = new SignedDataVerifier(
    [Buffer.from(g2), Buffer.from(g3)],
    true,
    environment,
    bundleId,
    appAppleId,
  );

  const transaction = await verifier.verifyAndDecodeTransaction(signedTransaction);

  if (transaction.productId !== productId) throw new Error("apple_product_mismatch");
  if (transaction.type !== "Consumable") throw new Error("apple_product_not_consumable");

  const quantity = Number(transaction.quantity ?? 1);
  if (!Number.isInteger(quantity) || quantity < 1 || quantity > 100) {
    throw new Error("invalid_quantity");
  }

  return {
    transactionId: transaction.transactionId,
    quantity,
    metadata: transaction,
  };
}

async function findPackage(productId: string) {
  const { data, error } = await adminClient
    .from("coin_packages")
    .select("id,coin_amount,store_product_id,is_active")
    .eq("store_product_id", productId)
    .eq("is_active", true)
    .maybeSingle();

  if (error) throw new Error(`package_lookup_failed:${error.message}`);
  if (!data) throw new Error("package_not_found");
  return data;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ success: false, message: "method_not_allowed" }, 405);

  try {
    const userId = await getUserId(request);
    const body = await request.json();
    const source = String(body.source ?? "");
    const productId = String(body.product_id ?? "").trim();
    const verificationData = String(body.verification_data ?? "").trim();

    if (!productId || !verificationData) {
      return json({ success: false, message: "invalid_purchase_payload" }, 400);
    }

    const packageRow = await findPackage(productId);
    let verified;
    let store: "google_play" | "app_store";

    if (source === "Google Play") {
      store = "google_play";
      verified = await verifyGooglePurchase(productId, verificationData);
    } else if (source === "app_store") {
      store = "app_store";
      verified = await verifyApplePurchase(productId, verificationData);
    } else {
      // Current Flutter IAP implementations expose the store source using
      // platform-specific values. Keep a conservative Apple fallback for
      // StoreKit signed JWS payloads rather than trusting an arbitrary client value.
      if (verificationData.split(".").length === 3) {
        store = "app_store";
        verified = await verifyApplePurchase(productId, verificationData);
      } else {
        return json({ success: false, message: "unsupported_store" }, 400);
      }
    }

    const { data, error } = await adminClient.rpc("grant_iap_coins_atomic", {
      p_user_id: userId,
      p_package_id: packageRow.id,
      p_store: store,
      p_product_id: productId,
      p_transaction_id: verified.transactionId,
      p_quantity: verified.quantity,
      p_metadata: verified.metadata,
    });

    if (error) throw new Error(`coin_grant_failed:${error.message}`);

    return json({
      success: true,
      duplicate: data?.duplicate === true,
      coin_amount: Number(data?.coin_amount ?? 0),
      balance: Number(data?.balance ?? 0),
      message: data?.duplicate === true
        ? "Bu satın alma daha önce hesabınıza tanımlandı."
        : `${Number(data?.coin_amount ?? 0)} Coin hesabınıza tanımlandı.`,
    });
  } catch (error) {
    console.error("verify-iap-purchase failed", error);
    const message = error instanceof Error ? error.message : "purchase_verification_failed";
    return json({ success: false, message }, 400);
  }
});