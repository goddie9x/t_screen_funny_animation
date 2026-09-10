import { writeFile } from "node:fs/promises";

const repo = process.env.GITHUB_REPOSITORY;
const tag = process.env.RELEASE_TAG;
if (!repo || !tag) {
  throw new Error("GITHUB_REPOSITORY and RELEASE_TAG are required");
}

const base = `https://github.com/${repo}/releases/download/${tag}`;
const play =
  process.env.PLAY_STORE_URL ||
  "https://play.google.com/store/apps/details?id=com.god.tscreenfunny";

const links = {
  play,
  android: `${base}/app-release.aab`,
  windows: `${base}/TScreenFunnyAnimation-windows-x64.zip`,
  tag,
  version: tag.replace(/^v/, ""),
};

await writeFile("release-links.json", `${JSON.stringify(links, null, 2)}\n`);
console.log(JSON.stringify(links, null, 2));
