import { readdir, readFile, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { driveAccessToken } from "./drive_token.mjs";
import { createZip, findFileId, replaceZip, shareAnyone } from "./drive_file.mjs";

const folderId = process.env.GOOGLE_DRIVE_FOLDER_ID;
if (!folderId) {
  throw new Error("GOOGLE_DRIVE_FOLDER_ID is missing");
}

const dist = process.argv[2] || "dist";
const token = await driveAccessToken();
const names = (await readdir(dist)).filter((name) => name.endsWith(".zip"));
if (names.length === 0) {
  throw new Error(`No zip files in ${dist}`);
}

const links = {};
for (const name of names) {
  const bytes = await readFile(join(dist, name));
  const existing = await findFileId(token, folderId, name);
  const fileId = existing
    ? await replaceZip(token, existing, bytes)
    : await createZip(token, folderId, name, bytes);
  links[keyFor(name)] = await shareAnyone(token, fileId);
  console.log(`${name} -> ${links[keyFor(name)]}`);
}

await writeFile("drive-links.json", `${JSON.stringify(links, null, 2)}\n`);

function keyFor(name) {
  if (name.includes("windows")) {
    return "windows";
  }
  if (name.includes("linux")) {
    return "linux";
  }
  if (name.includes("macos")) {
    return "macos";
  }
  return name;
}
