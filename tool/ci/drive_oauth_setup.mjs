import http from "node:http";
import { exec } from "node:child_process";

const clientId = process.env.GOOGLE_CLIENT_ID;
const clientSecret = process.env.GOOGLE_CLIENT_SECRET;
const port = 8765;
const redirectUri = `http://127.0.0.1:${port}/oauth`;

if (!clientId || !clientSecret) {
  throw new Error("Set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET, then rerun");
}

const authUrl = new URL("https://accounts.google.com/o/oauth2/v2/auth");
authUrl.searchParams.set("client_id", clientId);
authUrl.searchParams.set("redirect_uri", redirectUri);
authUrl.searchParams.set("response_type", "code");
authUrl.searchParams.set("access_type", "offline");
authUrl.searchParams.set("prompt", "consent");
authUrl.searchParams.set("scope", "https://www.googleapis.com/auth/drive");

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://127.0.0.1:${port}`);
  if (url.pathname !== "/oauth") {
    res.writeHead(404);
    res.end();
    return;
  }
  const code = url.searchParams.get("code");
  if (!code) {
    res.writeHead(400);
    res.end("Missing code");
    return;
  }
  const token = await exchangeCode(code);
  res.writeHead(200, { "Content-Type": "text/plain; charset=utf-8" });
  res.end("Refresh token printed in the terminal. You can close this tab.");
  console.log("\nGOOGLE_REFRESH_TOKEN=\n");
  console.log(token.refresh_token);
  console.log("\nPut that value in GitHub Actions secrets.\n");
  server.close();
  process.exit(0);
});

server.listen(port, () => {
  console.log("Sign in with the Google account that owns the Drive folder:");
  console.log(authUrl.toString());
  openBrowser(authUrl.toString());
});

async function exchangeCode(code) {
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      code,
      client_id: clientId,
      client_secret: clientSecret,
      redirect_uri: redirectUri,
      grant_type: "authorization_code",
    }),
  });
  const data = await response.json();
  if (!data.refresh_token) {
    throw new Error(data.error_description || "No refresh_token; retry with prompt=consent");
  }
  return data;
}

function openBrowser(url) {
  const command =
    process.platform === "win32"
      ? `cmd /c start "" "${url}"`
      : `xdg-open "${url}"`;
  exec(command);
}
