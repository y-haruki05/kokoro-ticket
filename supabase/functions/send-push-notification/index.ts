import { createClient } from "npm:@supabase/supabase-js@2";
import { importPKCS8, SignJWT } from "npm:jose@5";

Deno.serve(async (request) => {
  if (request.headers.get("x-webhook-secret") !== Deno.env.get("PUSH_WEBHOOK_SECRET")) {
    return new Response("unauthorized", { status: 401 });
  }
  const body = await request.json();
  const notificationID = body.record?.id ?? body.id;
  if (!notificationID) {
    return new Response("invalid payload", { status: 400 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data: notification, error: notificationError } = await supabase
    .from("notifications")
    .select("id,recipient_id,type,resource_type,resource_id,title,message")
    .eq("id", notificationID)
    .single();
  if (notificationError || !notification) {
    return new Response("notification not found", { status: 404 });
  }
  const { data: tokens, error } = await supabase
    .from("device_tokens")
    .select("id,apns_token,environment,bundle_id")
    .eq("user_id", notification.recipient_id)
    .eq("is_active", true);
  if (error) return new Response("token lookup failed", { status: 500 });

  const privateKey = await importPKCS8(
    Deno.env.get("APNS_PRIVATE_KEY")!.replaceAll("\\n", "\n"),
    "ES256",
  );
  const jwt = await new SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: Deno.env.get("APNS_KEY_ID")! })
    .setIssuer(Deno.env.get("APNS_TEAM_ID")!)
    .setIssuedAt()
    .sign(privateKey);

  const payload = {
    aps: { alert: { title: notification.title, body: notification.message }, sound: "default" },
    notification_id: notification.id,
    type: notification.type,
    resource_type: notification.resource_type,
    resource_id: notification.resource_id,
  };
  const results = await Promise.all((tokens ?? []).map(async (token) => {
    const { data: prior } = await supabase.from("push_deliveries")
      .select("delivered_at")
      .eq("notification_id", notification.id).eq("device_token_id", token.id)
      .maybeSingle();
    if (prior?.delivered_at) return true;
    await supabase.from("push_deliveries").upsert({
      notification_id: notification.id,
      device_token_id: token.id,
    });
    const host = token.environment === "production"
      ? "https://api.push.apple.com"
      : "https://api.sandbox.push.apple.com";
    const response = await fetch(`${host}/3/device/${token.apns_token}`, {
      method: "POST",
      headers: {
        authorization: `bearer ${jwt}`,
        "apns-topic": token.bundle_id,
        "apns-push-type": "alert",
        "apns-id": notification.id,
      },
      body: JSON.stringify(payload),
    });
    if (response.status === 410) {
      await supabase.from("device_tokens").update({ is_active: false }).eq("id", token.id);
    }
    await supabase.from("push_deliveries").update({
      delivered_at: response.ok ? new Date().toISOString() : null,
      last_error: response.ok ? null : `apns_${response.status}`,
    }).eq("notification_id", notification.id).eq("device_token_id", token.id);
    return response.ok || response.status === 410;
  }));
  return Response.json({ delivered: results.filter(Boolean).length });
});
