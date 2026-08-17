import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const WEBHOOK_SECRET = Deno.env.get("TASKORA_WEBHOOK_SECRET") ?? "";
const serviceAccountRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "";

if (!WEBHOOK_SECRET) console.error("TASKORA_WEBHOOK_SECRET is not configured");

function base64UrlEncode(input: Uint8Array): string {
  let binary = "";
  const chunkSize = 0x8000;

  for (let i = 0; i < input.length; i += chunkSize) {
    binary += String.fromCharCode(
      ...input.subarray(i, Math.min(i + chunkSize, input.length)),
    );
  }

  return btoa(binary)
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

function utf8Bytes(value: string): Uint8Array {
  return new TextEncoder().encode(value);
}

function pemToDer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");

  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);

  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }

  return bytes.buffer;
}

async function getGoogleAccessToken(
  serviceAccount: Record<string, string>,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  const header = base64UrlEncode(
    utf8Bytes(
      JSON.stringify({
        alg: "RS256",
        typ: "JWT",
      }),
    ),
  );

  const claimSet = base64UrlEncode(
    utf8Bytes(
      JSON.stringify({
        iss: serviceAccount.client_email,
        scope: "https://www.googleapis.com/auth/firebase.messaging",
        aud: "https://oauth2.googleapis.com/token",
        iat: now,
        exp: now + 3600,
      }),
    ),
  );

  const unsignedToken = `${header}.${claimSet}`;

  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(serviceAccount.private_key),
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"],
  );

  const signature = new Uint8Array(
    await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      privateKey,
      utf8Bytes(unsignedToken),
    ),
  );

  const tokenResponse = await fetch(
    "https://oauth2.googleapis.com/token",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: `${unsignedToken}.${base64UrlEncode(signature)}`,
      }),
    },
  );

  const text = await tokenResponse.text();

  let body: Record<string, unknown>;

  try {
    body = JSON.parse(text) as Record<string, unknown>;
  } catch {
    throw new Error(
      `Google OAuth cevabı JSON değil. HTTP ${tokenResponse.status}: ${text.slice(0, 500)}`,
    );
  }

  if (!tokenResponse.ok || !body.access_token) {
    throw new Error(
      `Google OAuth token alınamadı. HTTP ${tokenResponse.status}: ${JSON.stringify(body)}`,
    );
  }

  return body.access_token as string;
}

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response("Method Not Allowed", {
        status: 405,
      });
    }

    const incomingSecret = req.headers.get(
      "x-taskora-webhook-secret",
    );

    if (!WEBHOOK_SECRET || incomingSecret !== WEBHOOK_SECRET) {
      return new Response(
        JSON.stringify({
          error: "Unauthorized",
        }),
        {
          status: 401,
          headers: {
            "Content-Type": "application/json",
          },
        },
      );
    }

    const rawBody = await req.text();

    console.log("RAW REQUEST BODY:", rawBody);

    const jsonStart = rawBody.indexOf("{");

    if (jsonStart === -1) {
      throw new Error(
        "Request body içinde JSON payload bulunamadı.",
      );
    }

    let payload;

    try {
      payload = JSON.parse(
        rawBody.slice(jsonStart),
      );
    } catch (error) {
      throw new Error(
        `Request body JSON parse hatası: ${
          error instanceof Error
            ? error.message
            : String(error)
        } | RAW BODY: ${rawBody}`,
      );
    }

    const record = payload?.record;

    if (
      !record?.user_id ||
      !record?.title ||
      !record?.body ||
      !record?.type
    ) {
      return new Response(
        JSON.stringify({
          error: "Geçersiz notification payload.",
        }),
        {
          status: 400,
          headers: {
            "Content-Type": "application/json",
          },
        },
      );
    }

    if (!serviceAccountRaw) {
      throw new Error(
        "FIREBASE_SERVICE_ACCOUNT secret tanımlı değil.",
      );
    }

    let serviceAccount: Record<string, string>;

    try {
      serviceAccount = JSON.parse(
        serviceAccountRaw,
      ) as Record<string, string>;
    } catch (error) {
      throw new Error(
        `FIREBASE_SERVICE_ACCOUNT JSON parse hatası: ${
          error instanceof Error
            ? error.message
            : String(error)
        }`,
      );
    }

    if (
      !serviceAccount.project_id ||
      !serviceAccount.client_email ||
      !serviceAccount.private_key
    ) {
      throw new Error(
        "FIREBASE_SERVICE_ACCOUNT eksik: project_id, client_email ve private_key zorunlu.",
      );
    }

    const supabaseUrl =
      Deno.env.get("SUPABASE_URL") ?? "";

    const serviceRoleKey =
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl) {
      throw new Error(
        "SUPABASE_URL secret bulunamadı.",
      );
    }

    if (!serviceRoleKey) {
      throw new Error(
        "SUPABASE_SERVICE_ROLE_KEY secret bulunamadı.",
      );
    }

    const supabase = createClient(
      supabaseUrl,
      serviceRoleKey,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      },
    );

    const userId = String(record.user_id).trim();

    console.log("TOKEN LOOKUP START:", {
      userId,
      userIdLength: userId.length,
      supabaseUrl,
      keyLength: serviceRoleKey.length,
    });

    const {
      data: allTokens,
      error: allTokensError,
    } = await supabase
      .from("user_push_tokens")
      .select(
        "id, user_id, token, platform",
      )
      .limit(100);

    console.log("ALL PUSH TOKENS RESULT:", {
      error:
        allTokensError?.message ?? null,

      count:
        allTokens?.length ?? 0,

      rows:
        allTokens?.map((row) => ({
          id: row.id,
          user_id: row.user_id,
          user_id_string:
            String(row.user_id),
          user_id_length:
            String(row.user_id).length,
          platform: row.platform,
        })) ?? [],
    });

    if (allTokensError) {
      throw new Error(
        `user_push_tokens okunamadı: ${allTokensError.message}`,
      );
    }

    const tokens = (
      allTokens ?? []
    ).filter((row) => {
      const rowUserId =
        String(row.user_id).trim();

      return rowUserId === userId;
    });

    console.log("FINAL TOKEN MATCH:", {
      requestedUserId: userId,
      requestedUserIdLength:
        userId.length,
      count: tokens.length,
      tokens: tokens.map((row) => ({
        id: row.id,
        user_id: row.user_id,
        platform: row.platform,
      })),
    });

    if (tokens.length === 0) {
      console.error(
        "TOKEN BULUNAMADI:",
        {
          requestedUserId: userId,
          requestedUserIdLength:
            userId.length,

          availableTokenCount:
            allTokens?.length ?? 0,

          availableUserIds:
            allTokens?.map((row) =>
              String(row.user_id).trim()
            ) ?? [],
        },
      );

      return new Response(
        JSON.stringify({
          success: false,
          error: "Push token bulunamadı.",
          userId,
          availableTokenCount:
            allTokens?.length ?? 0,
        }),
        {
          status: 404,
          headers: {
            "Content-Type":
              "application/json",
          },
        },
      );
    }

    const accessToken =
      await getGoogleAccessToken(
        serviceAccount,
      );

    const endpoint =
      `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;

    let sent = 0;

    const invalidTokenIds: string[] = [];

    for (const tokenRow of tokens) {
      const fcmPayload = {
        message: {
          token: tokenRow.token,

          notification: {
            title: record.title,
            body: record.body,
          },

          data: {
            notification_id:
              String(record.id ?? ""),

            user_id:
              String(record.user_id),

            type:
              String(record.type),

            related_id:
              String(record.related_id ?? ""),
          },

          android: {
            priority: "high",

            notification: {
              channel_id:
                "taskora_notifications",
            },
          },

          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        },
      };

      const fcmResponse = await fetch(
        endpoint,
        {
          method: "POST",

          headers: {
            Authorization:
              `Bearer ${accessToken}`,

            "Content-Type":
              "application/json",
          },

          body:
            JSON.stringify(fcmPayload),
        },
      );

      const fcmResponseText =
        await fcmResponse.text();

      let fcmResult:
        Record<string, unknown>;

      try {
        fcmResult =
          JSON.parse(
            fcmResponseText,
          ) as Record<string, unknown>;
      } catch {
        console.error(
          "FCM cevabı JSON değil",
          {
            status:
              fcmResponse.status,

            response:
              fcmResponseText.slice(
                0,
                500,
              ),
          },
        );

        continue;
      }

      if (fcmResponse.ok) {
        sent++;

        console.log(
          "FCM GÖNDERİLDİ:",
          {
            tokenId:
              tokenRow.id,

            platform:
              tokenRow.platform,
          },
        );

        continue;
      }

      const errorCode =
        fcmResult?.error?.details?.find(
          (
            detail:
              Record<string, unknown>,
          ) =>
            detail?.["@type"] ===
            "type.googleapis.com/google.firebase.fcm.v1.FcmError",
        )?.errorCode;

      if (
        errorCode ===
          "UNREGISTERED" ||
        errorCode ===
          "INVALID_ARGUMENT"
      ) {
        invalidTokenIds.push(
          tokenRow.id,
        );
      }

      console.error(
        "FCM gönderim hatası",
        {
          tokenId:
            tokenRow.id,

          platform:
            tokenRow.platform,

          status:
            fcmResponse.status,

          response:
            fcmResult,
        },
      );
    }

    if (
      invalidTokenIds.length > 0
    ) {
      const {
        error: cleanupError,
      } = await supabase
        .from("user_push_tokens")
        .delete()
        .in(
          "id",
          invalidTokenIds,
        );

      if (cleanupError) {
        console.error(
          "Geçersiz token temizliği başarısız:",
          cleanupError.message,
        );
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        sent,
        total: tokens.length,
        removedInvalidTokens:
          invalidTokenIds.length,
      }),
      {
        status: 200,

        headers: {
          "Content-Type":
            "application/json",
        },
      },
    );
  } catch (error) {
    console.error(
      "send-fcm error:",
      error,
    );

    return new Response(
      JSON.stringify({
        success: false,

        error:
          error instanceof Error
            ? error.message
            : String(error),
      }),
      {
        status: 500,

        headers: {
          "Content-Type":
            "application/json",
        },
      },
    );
  }
});