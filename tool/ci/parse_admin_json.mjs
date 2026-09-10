const PREFIX = ")]}',";

export function parseAdminJson(raw) {
  const text = String(raw ?? "").trimStart();
  const body = text.startsWith(PREFIX)
    ? text.slice(PREFIX.length).trimStart()
    : text;
  if (!body) {
    return {};
  }
  return JSON.parse(body);
}
