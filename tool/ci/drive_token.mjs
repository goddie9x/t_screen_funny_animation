export async function driveAccessToken() {
  const missing = [
    "GOOGLE_CLIENT_ID",
    "GOOGLE_CLIENT_SECRET",
    "GOOGLE_REFRESH_TOKEN",
  ].filter((name) => !process.env[name]?.trim());
  if (missing.length > 0) {
    throw new Error(
      `Missing GitHub secrets: ${missing.join(", ")}. Add them under Settings → Secrets → Actions (same names). Local one-time setup: node tool/ci/drive_oauth_setup.mjs`,
    );
  }
  return oauthAccessToken();
}

async function oauthAccessToken() {
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "refresh_token",
      client_id: process.env.GOOGLE_CLIENT_ID,
      client_secret: process.env.GOOGLE_CLIENT_SECRET,
      refresh_token: process.env.GOOGLE_REFRESH_TOKEN,
    }),
  });
  const data = await response.json();
  if (!data.access_token) {
    throw new Error(data.error_description || "OAuth refresh failed");
  }
  return data.access_token;
}
