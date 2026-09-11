import { access, readFile, writeFile } from "node:fs/promises";

const version =
  process.env.RELEASE_VERSION ||
  (process.env.RELEASE_TAG || "").replace(/^v/, "") ||
  "";
if (!version) {
  throw new Error("RELEASE_VERSION or RELEASE_TAG is required");
}

const play =
  process.env.PLAY_STORE_URL ||
  "https://play.google.com/store/apps/details?id=com.god.tscreenfunny";

let drive = {};
try {
  await access("drive-links.json");
  drive = JSON.parse(await readFile("drive-links.json", "utf8"));
} catch {
  drive = {};
}

// Destinations only: Play (Android) + Drive (Windows). No GitHub Release assets.
const links = {
  play,
  android: play,
  windows: drive.windows || "",
  tag: process.env.RELEASE_TAG || `v${version}`,
  version,
};

await writeFile("release-links.json", `${JSON.stringify(links, null, 2)}\n`);
console.log(JSON.stringify(links, null, 2));
