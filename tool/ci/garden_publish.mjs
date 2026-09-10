import { readFile } from "node:fs/promises";
import { requestJson } from "./http_json.mjs";
import {
  buildItemBody,
  itemTag,
  itemTitle,
  samePublicFields,
} from "./garden_item_body.mjs";
import { parsePubspecVersion } from "./read_pubspec_version.mjs";

const base = (process.env.HMT9X_BASE || "https://hmt9x.dev").replace(/\/$/, "");
const user = process.env.HMT9X_ADMIN_USER;
const pass = process.env.HMT9X_ADMIN_PASS;
if (!user || !pass) {
  throw new Error("HMT9X_ADMIN_USER / HMT9X_ADMIN_PASS are missing");
}

const links = JSON.parse(await readFile("release-links.json", "utf8"));
const version =
  links.version ||
  process.env.RELEASE_VERSION ||
  parsePubspecVersion(await readFile("pubspec.yaml", "utf8"));
const token = await login();
const categorySlug = await resolveCategory(token);
const sectionIds = await resolveSectionIds(token, categorySlug);
const body = buildItemBody({ categorySlug, links, version, sectionIds });
const current = await findItem(token);
if (current && samePublicFields(current, body)) {
  console.log("Garden item is already up to date");
  process.exit(0);
}
if (current) {
  await requestJson(`${base}/api/admin/items/${current._id}`, {
    method: "PUT",
    token,
    body,
  });
  console.log(`Updated garden item ${current._id}`);
} else {
  const created = await requestJson(`${base}/api/admin/items`, {
    method: "POST",
    token,
    body,
  });
  console.log(`Created garden item ${created._id || ""}`);
}

async function login() {
  const data = await requestJson(`${base}/api/admin/login`, {
    method: "POST",
    body: { username: user, password: pass },
  });
  if (!data.token) {
    throw new Error("Login returned no token");
  }
  return data.token;
}

async function resolveCategory(token) {
  const forced = process.env.HMT9X_CATEGORY_SLUG;
  if (forced) {
    return forced;
  }
  const rows = await requestJson(`${base}/api/admin/categories`, { token });
  const list = Array.isArray(rows) ? rows : [];
  const needles = [
    "mobile",
    "android",
    "app",
    "ung-dung",
    "desktop",
    "tool",
    "cong-cu",
    "code",
    "lap-trinh",
  ];
  const hit = list.find((row) =>
    needles.some((needle) =>
      `${row.slug} ${row.name}`.toLowerCase().includes(needle),
    ),
  );
  if (!hit) {
    throw new Error("Set HMT9X_CATEGORY_SLUG; no app/code category found");
  }
  return hit.slug;
}

async function resolveSectionIds(token, categorySlug) {
  const forced = process.env.HMT9X_SECTION_ID;
  if (forced) {
    return [forced];
  }
  const rows = await requestJson(`${base}/api/admin/sections`, { token });
  const list = Array.isArray(rows) ? rows : [];
  const forCategory = list.filter((row) => row.categorySlug === categorySlug);
  const needles = ["mobile", "android", "app", "ung-dung", "desktop", "cong-cu", "tool"];
  const preferred = forCategory.filter((row) =>
    needles.some((needle) =>
      `${row.title || ""} ${row.slug || ""}`.toLowerCase().includes(needle),
    ),
  );
  const auto = forCategory.filter((row) => row.isAutoCollect);
  const picks = (preferred.length > 0 ? preferred : auto.length > 0 ? auto : forCategory)
    .map((row) => row._id)
    .filter(Boolean);
  if (picks.length === 0) {
    throw new Error(
      `Category "${categorySlug}" has no sections. Create one in admin or set HMT9X_SECTION_ID.`,
    );
  }
  return picks;
}

async function findItem(token) {
  const rows = await requestJson(`${base}/api/admin/items`, { token });
  const list = Array.isArray(rows) ? rows : [];
  return (
    list.find((row) => row.title === itemTitle()) ||
    list.find((row) => row.title === "TScreen Funny Animation") ||
    list.find((row) => (row.tags || []).includes(itemTag())) ||
    null
  );
}
