import { readFile } from "node:fs/promises";

export function parsePubspecVersion(text) {
  const match = text.match(/^version:\s*([0-9]+\.[0-9]+\.[0-9]+)/m);
  if (!match) {
    throw new Error("pubspec.yaml has no version");
  }
  return match[1];
}

export function parsePubspecBuild(text) {
  const match = text.match(/^version:\s*[0-9]+\.[0-9]+\.[0-9]+\+([0-9]+)/m);
  return match ? Number(match[1]) : 0;
}

if (process.argv[1]?.includes("read_pubspec_version.mjs")) {
  const text = await readFile("pubspec.yaml", "utf8");
  process.stdout.write(`${parsePubspecVersion(text)}\n`);
}
