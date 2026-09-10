import { parseAdminJson } from "./parse_admin_json.mjs";

export async function requestJson(url, { method = "GET", token, body } = {}) {
  const headers = { Accept: "application/json" };
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }
  if (body !== undefined) {
    headers["Content-Type"] = "application/json";
  }
  const response = await fetch(url, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const raw = await response.text();
  let data = {};
  try {
    data = parseAdminJson(raw);
  } catch {
    data = { error: raw.slice(0, 400) };
  }
  if (!response.ok) {
    const detail = [data.error, data.details].filter(Boolean).join(" — ");
    throw new Error(
      `${method} ${url} failed (${response.status}): ${detail || response.statusText}`,
    );
  }
  return data;
}
