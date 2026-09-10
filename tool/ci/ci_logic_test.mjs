import assert from "node:assert/strict";
import { test } from "node:test";
import { samePublicFields } from "./garden_item_body.mjs";
import { parseAdminJson } from "./parse_admin_json.mjs";
import { parsePubspecBuild, parsePubspecVersion } from "./read_pubspec_version.mjs";

test("strips the admin JSON prefix", () => {
  const data = parseAdminJson(")]}',\n{\"token\":\"abc\"}\n");
  assert.equal(data.token, "abc");
});

test("reads the pubspec version number", () => {
  assert.equal(parsePubspecVersion("name: x\nversion: 1.0.2+3\n"), "1.0.2");
  assert.equal(parsePubspecBuild("name: x\nversion: 1.0.2+3\n"), 3);
});

test("skips a garden update when public fields match", () => {
  const next = {
    shortDescription: "a",
    shortDescriptionEn: "a-en",
    content: "b",
    contentEn: "b-en",
    titleEn: "TScreen Funny Animation",
    downloadUrl: "https://play.google.com/store/apps/details?id=com.god.tscreenfunny",
    thumbnail: "https://img",
  };
  assert.equal(samePublicFields(next, next), true);
  assert.equal(samePublicFields({ ...next, contentEn: "c-en" }, next), false);
});
