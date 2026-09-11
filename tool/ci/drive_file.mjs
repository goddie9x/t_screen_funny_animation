const API = "https://www.googleapis.com/drive/v3";
const UPLOAD = "https://www.googleapis.com/upload/drive/v3";

export async function findFileId(token, folderId, name) {
  const query = `name='${name}' and '${folderId}' in parents and trashed=false`;
  const url = withDriveFlags(
    `${API}/files?q=${encodeURIComponent(query)}&fields=files(id,name)`,
  );
  const data = await driveJson(token, url);
  return data.files?.[0]?.id ?? "";
}

export async function createZip(token, folderId, name, bytes) {
  const boundary = "tExtendBoundary";
  const meta = JSON.stringify({ name, parents: [folderId] });
  const body = Buffer.concat([
    Buffer.from(
      `--${boundary}\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n${meta}\r\n`,
    ),
    Buffer.from(`--${boundary}\r\nContent-Type: application/zip\r\n\r\n`),
    bytes,
    Buffer.from(`\r\n--${boundary}--`),
  ]);
  const data = await driveJson(
    token,
    withDriveFlags(`${UPLOAD}/files?uploadType=multipart`),
    {
      method: "POST",
      headers: { "Content-Type": `multipart/related; boundary=${boundary}` },
      body,
    },
  );
  return data.id;
}

export async function replaceZip(token, fileId, bytes) {
  await driveJson(
    token,
    withDriveFlags(`${UPLOAD}/files/${fileId}?uploadType=media`),
    {
      method: "PATCH",
      headers: { "Content-Type": "application/zip" },
      body: bytes,
    },
  );
  return fileId;
}

export async function shareAnyone(token, fileId) {
  try {
    await driveJson(
      token,
      withDriveFlags(`${API}/files/${fileId}/permissions`),
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ role: "reader", type: "anyone" }),
      },
    );
  } catch (error) {
    if (!String(error.message).toLowerCase().includes("already")) {
      throw error;
    }
  }
  return `https://drive.google.com/file/d/${fileId}/view?usp=sharing`;
}

function withDriveFlags(url) {
  const parsed = new URL(url);
  parsed.searchParams.set("supportsAllDrives", "true");
  parsed.searchParams.set("includeItemsFromAllDrives", "true");
  return parsed.toString();
}

async function driveJson(token, url, init = {}) {
  const response = await fetch(url, {
    ...init,
    headers: { Authorization: `Bearer ${token}`, ...(init.headers ?? {}) },
  });
  const text = await response.text();
  const data = text ? JSON.parse(text) : {};
  if (!response.ok) {
    throw new Error(data.error?.message || text || response.statusText);
  }
  return data;
}
