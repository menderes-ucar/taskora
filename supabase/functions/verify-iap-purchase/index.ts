import { createClient } from "https://esm.sh/@supabase/supabase-js@2.56.0";
import { SignJWT, importPKCS8 } from "npm:jose@6.0.10";
import {
  Environment,
  SignedDataVerifier,
} from "npm:@apple/app-store-server-library@3.1.0";
import { Buffer } from "node:buffer";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const adminClient = createClient(
  supabaseUrl,
  serviceRoleKey,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  },
);

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

async function getUserId(request: Request): Promise<string> {
  const authorization = request.headers.get("Authorization");

  if (!authorization?.startsWith("Bearer ")) {
    throw new Error("unauthorized");
  }

  const token = authorization.substring("Bearer ".length).trim();

  if (!token) {
    throw new Error("unauthorized");
  }

  const client = createClient(
    supabaseUrl,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    {
      global: {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      },
    },
  );

  const { data, error } = await client.auth.getUser(token);

  if (error || !data.user) {
    throw new Error("unauthorized");
  }

  return data.user.id;
}

/**
 * Reads GOOGLE_PLAY_SERVICE_ACCOUNT_JSON safely.
 *
 * Supported formats:
 *
 * 1. Normal service-account JSON:
 *    {"type":"service_account", ...}
 *
 * 2. Base64 encoded service-account JSON.
 *
 * Base64 is preferred because PowerShell / shell quoting can corrupt
 * service-account JSON, especially the private_key field.
 */
function parseGoogleServiceAccount(raw: string): Record<string, unknown> {
  const value = raw.trim();

  if (!value) {
    throw new Error("google_play_service_account_empty");
  }

  let parsed: unknown;

  // First try normal JSON.
  try {
    parsed = JSON.parse(value);
  } catch {
    // If normal JSON failed, try Base64.
    try {
      const decoded = atob(value);
      const decodedText = new TextDecoder().decode(
        Uint8Array.from(decoded, (char) => char.charCodeAt(0)),
      );

      parsed = JSON.parse(decodedText);
    } catch {
      throw new Error(
        "google_service_account_json_invalid_or_base64_invalid",
      );
    }
  }

  if (
    typeof parsed !== "object" ||
    parsed === null ||
    Array.isArray(parsed)
  ) {
    throw new Error("google_service_account_invalid");
  }

  const serviceAccount = parsed as Record<string, unknown>;

  const clientEmail = serviceAccount.client_email;
  const privateKey = serviceAccount.private_key;

  if (
    typeof clientEmail !== "string" ||
    clientEmail.trim().isEmpty
  ) {
    throw new Error("google_service_account_client_email_missing");
  }

  if (
    typeof privateKey !== "string" ||
    privateKey.trim().isEmpty
  ) {
    throw new Error("google_service_account_private_key_missing");
  }

  return serviceAccount;
}

async function googleAccessToken(): Promise<string> {
  const raw = Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON");

  if (!raw) {
    throw new Error("google_play_not_configured");
  }

  console.log(
    `Google service account secret loaded: length=${raw.length}`,
  );

  const serviceAccount = parseGoogleServiceAccount(raw);

  const clientEmail = String(serviceAccount.client_email).trim();

  let privateKey = String(serviceAccount.private_key);

  // Handle both escaped and real newlines.
  privateKey = privateKey.replace(/\\n/g, "\n").trim();

  if (
    !privateKey.includes("-----BEGIN PRIVATE KEY-----") ||
    !privateKey.includes("-----END PRIVATE KEY-----")
  ) {
    throw new Error("google_service_account_private_key_invalid");
  }

  const privateKeyObject = await importPKCS8(
    privateKey,
    "RS256",
  );

  const now = Math.floor(Date.now() / 1000);

  const assertion = await new SignJWT({
    scope: "https://www.googleapis.com/auth/androidpublisher",
  })
    .setProtectedHeader({
      alg: "RS256",
      typ: "JWT",
    })
    .setIssuer(clientEmail)
    .setSubject(clientEmail)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(privateKeyObject);

  const tokenResponse = await fetch(
    "https://oauth2.googleapis.com/token",
    {
      method: "POST",
      headers: {
        "Content-Type":
          "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        grant_type:
          "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion,
      }),
    },
  );

  if (!tokenResponse.ok) {
    const text = await tokenResponse.text();

    console.error(
      `Google OAuth token request failed: ${tokenResponse.status} ${text}`,
    );

    throw new Error(
      `google_auth_failed:${text}`,
    );
  }

  const token = await tokenResponse.json();

  if (
    !token ||
    typeof token.access_token !== "string" ||
    !token.access_token
  ) {
    throw new Error("google_access_token_missing");
  }

  console.log("Google OAuth access token obtained successfully.");

  return token.access_token;
}

async function verifyGooglePurchase(
  productId: string,
  purchaseToken: string,
) {
  const packageName = Deno.env.get(
    "GOOGLE_PLAY_PACKAGE_NAME",
  );

  if (!packageName) {
    throw new Error("google_play_not_configured");
  }

  console.log(
    `Google purchase verification started: product=${productId}`,
  );

  const accessToken = await googleAccessToken();

  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
    `${encodeURIComponent(packageName)}/purchases/productsv2/tokens/` +
    `${encodeURIComponent(purchaseToken)}`;

  const response = await fetch(url, {
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });

  if (!response.ok) {
    const text = await response.text();

    console.error(
      `Google purchase verification failed: ${response.status} ${text}`,
    );

    throw new Error(
      `google_purchase_invalid:${text}`,
    );
  }

  const purchase = await response.json();

  console.log(
    `Google purchase response received: product=${productId}`,
  );

  const lineItems = Array.isArray(
    purchase.productLineItem,
  )
    ? purchase.productLineItem
    : [];

  const line = lineItems.find(
    (item: Record<string, unknown>) =>
      item.productId === productId,
  );

  if (!line) {
    console.error(
      `Google product mismatch: expected=${productId}`,
    );

    throw new Error("google_product_mismatch");
  }

  const purchaseState =
    purchase.purchaseStateContext?.purchaseState;

  console.log(
    `Google purchase state: ${purchaseState}`,
  );

  if (purchaseState !== "PURCHASED") {
    throw new Error(
      "google_purchase_not_completed",
    );
  }

  const quantity = Number(
    line.productOfferDetails?.quantity ?? 1,
  );

  if (
    !Number.isInteger(quantity) ||
    quantity < 1 ||
    quantity > 100
  ) {
    throw new Error("invalid_quantity");
  }

  return {
    transactionId: purchaseToken,
    quantity,
    metadata: purchase,
  };
}

async function consumeGooglePurchase(
  productId: string,
  purchaseToken: string,
): Promise<void> {
  const packageName = Deno.env.get(
    "GOOGLE_PLAY_PACKAGE_NAME",
  );

  if (!packageName) {
    throw new Error("google_play_not_configured");
  }

  console.log(
    `Google consume started: product=${productId}`,
  );

  const accessToken = await googleAccessToken();

  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
    `${encodeURIComponent(packageName)}/purchases/products/` +
    `${encodeURIComponent(productId)}/tokens/` +
    `${encodeURIComponent(purchaseToken)}:consume`;

  const response = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({}),
  });

  if (!response.ok) {
    const text = await response.text();

    console.error(
      `Google consume failed: ${response.status} ${text}`,
    );

    throw new Error(
      `google_consume_failed:${text}`,
    );
  }

  console.log(
    `Google purchase consumed successfully: product=${productId}`,
  );
}

async function verifyApplePurchase(
  productId: string,
  signedTransaction: string,
) {
  const bundleId = Deno.env.get(
    "APPLE_BUNDLE_ID",
  );

  if (!bundleId) {
    throw new Error("apple_not_configured");
  }

  if (signedTransaction.split(".").length !== 3) {
    throw new Error(
      "apple_signed_transaction_required",
    );
  }

  const [g2Response, g3Response] =
    await Promise.all([
      fetch(
        "https://www.apple.com/certificateauthority/AppleRootCA-G2.cer",
      ),
      fetch(
        "https://www.apple.com/certificateauthority/AppleRootCA-G3.cer",
      ),
    ]);

  if (!g2Response.ok) {
    throw new Error(
      "apple_root_ca_g2_download_failed",
    );
  }

  if (!g3Response.ok) {
    throw new Error(
      "apple_root_ca_g3_download_failed",
    );
  }

  const [g2, g3] = await Promise.all([
    g2Response.arrayBuffer(),
    g3Response.arrayBuffer(),
  ]);

  const environment =
    Deno.env.get("APPLE_ENVIRONMENT") ===
    "PRODUCTION"
      ? Environment.PRODUCTION
      : Environment.SANDBOX;

  const appAppleId =
    environment === Environment.PRODUCTION
      ? Number(
          Deno.env.get("APPLE_APPLE_ID"),
        )
      : undefined;

  if (
    environment === Environment.PRODUCTION &&
    !Number.isFinite(appAppleId)
  ) {
    throw new Error(
      "apple_app_id_not_configured",
    );
  }

  const verifier = new SignedDataVerifier(
    [
      Buffer.from(g2),
      Buffer.from(g3),
    ],
    true,
    environment,
    bundleId,
    appAppleId,
  );

  const transaction =
    await verifier.verifyAndDecodeTransaction(
      signedTransaction,
    );

  if (transaction.productId !== productId) {
    throw new Error(
      "apple_product_mismatch",
    );
  }

  if (transaction.type !== "Consumable") {
    throw new Error(
      "apple_product_not_consumable",
    );
  }

  const quantity = Number(
    transaction.quantity ?? 1,
  );

  if (
    !Number.isInteger(quantity) ||
    quantity < 1 ||
    quantity > 100
  ) {
    throw new Error("invalid_quantity");
  }

  return {
    transactionId:
      transaction.transactionId,
    quantity,
    metadata: transaction,
  };
}

async function findPackage(productId: string) {
  console.log(
    `Looking up coin package: ${productId}`,
  );

  const { data, error } =
    await adminClient
      .from("coin_packages")
      .select(
        "id,coin_amount,store_product_id,is_active",
      )
      .eq(
        "store_product_id",
        productId,
      )
      .eq("is_active", true)
      .maybeSingle();

  if (error) {
    throw new Error(
      `package_lookup_failed:${error.message}`,
    );
  }

  if (!data) {
    throw new Error(
      "package_not_found",
    );
  }

  console.log(
    `Coin package found: id=${data.id}, coins=${data.coin_amount}`,
  );

  return data;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  if (request.method !== "POST") {
    return json(
      {
        success: false,
        message: "method_not_allowed",
      },
      405,
    );
  }

  try {
    const userId = await getUserId(
      request,
    );

    console.log(
      `IAP request authenticated: user=${userId}`,
    );

    const body = await request.json();

    const source = String(
      body.source ?? "",
    )
      .trim()
      .toLowerCase();

    const productId = String(
      body.product_id ?? "",
    ).trim();

    const verificationData = String(
      body.verification_data ?? "",
    ).trim();

    console.log(
      `IAP request received: ${JSON.stringify({
        source,
        productId,
        hasVerificationData:
          verificationData.length > 0,
      })}`,
    );

    if (
      !productId ||
      !verificationData
    ) {
      return json(
        {
          success: false,
          message:
            "invalid_purchase_payload",
        },
        400,
      );
    }

    const packageRow =
      await findPackage(productId);

    let verified: {
      transactionId: string;
      quantity: number;
      metadata: unknown;
    };

    let store:
      | "google_play"
      | "app_store";

    if (
      source === "google_play" ||
      source === "google play"
    ) {
      store = "google_play";

      console.log(
        "Store selected: google_play",
      );

      verified =
        await verifyGooglePurchase(
          productId,
          verificationData,
        );
    } else if (
      source === "app_store" ||
      source === "app store"
    ) {
      store = "app_store";

      console.log(
        "Store selected: app_store",
      );

      verified =
        await verifyApplePurchase(
          productId,
          verificationData,
        );
    } else {
      /*
       * Some Flutter IAP implementations can expose
       * different source strings depending on
       * platform/plugin version.
       *
       * Apple StoreKit signed JWS contains exactly
       * three dot-separated sections.
       *
       * We only use this fallback for Apple data.
       */
      if (
        verificationData.split(".").length ===
        3
      ) {
        store = "app_store";

        console.log(
          "Store selected through Apple JWS fallback",
        );

        verified =
          await verifyApplePurchase(
            productId,
            verificationData,
          );
      } else {
        console.error(
          `Unsupported store: ${source}`,
        );

        return json(
          {
            success: false,
            message:
              `unsupported_store:${source}`,
          },
          400,
        );
      }
    }

    console.log(
      `Purchase verified: store=${store}, transaction=${verified.transactionId}, quantity=${verified.quantity}`,
    );

    const { data, error } =
      await adminClient.rpc(
        "grant_iap_coins_atomic",
        {
          p_user_id: userId,
          p_package_id:
            packageRow.id,
          p_store: store,
          p_product_id:
            productId,
          p_transaction_id:
            verified.transactionId,
          p_quantity:
            verified.quantity,
          p_metadata:
            verified.metadata,
        },
      );

    if (error) {
      console.error(
        `Coin grant RPC failed: ${error.message}`,
      );

      throw new Error(
        `coin_grant_failed:${error.message}`,
      );
    }

    console.log(
      `Coin grant RPC completed: ${JSON.stringify(data)}`,
    );

    /*
     * IMPORTANT:
     *
     * Google Play consumable purchases are consumed
     * only after successful server verification and
     * successful atomic coin granting.
     *
     * This means the Flutter client must NOT consume
     * the same Google purchase a second time.
     */
    if (store === "google_play") {
      await consumeGooglePurchase(
        productId,
        verificationData,
      );
    }

    const duplicate =
      data?.duplicate === true;

    const coinAmount = Number(
      data?.coin_amount ?? 0,
    );

    const balance = Number(
      data?.balance ?? 0,
    );

    console.log(
      `IAP completed: duplicate=${duplicate}, coinAmount=${coinAmount}, balance=${balance}`,
    );

    return json({
      success: true,
      duplicate,
      coin_amount: coinAmount,
      balance,
      message: duplicate
        ? "Bu satın alma daha önce hesabınıza tanımlandı."
        : `${coinAmount} Coin hesabınıza tanımlandı.`,
    });
  } catch (error) {
    console.error(
      "verify-iap-purchase failed",
      error,
    );

    const message =
      error instanceof Error
        ? error.message
        : "purchase_verification_failed";

    return json(
      {
        success: false,
        message,
      },
      400,
    );
  }
});