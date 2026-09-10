const TITLE = "T Screen Funny Animation";
const TITLE_ALT = "TScreen Funny Animation";
const TAG = "tscreenfunny";
const THUMB = "https://hmt9x.dev/default-thumb.png";
const PRIVACY = "https://goddie9x.github.io/privacy/tscreenfunny-privacy.html";

export function itemTitle() {
  return TITLE;
}

export function itemTag() {
  return TAG;
}

export function buildItemBody({ categorySlug, links, version, sectionIds = [] }) {
  const play = links.play || "";
  const android = links.android || "";
  const windows = links.windows || "";
  return {
    title: TITLE,
    titleEn: TITLE_ALT,
    categorySlug,
    shortDescription:
      "Buddy hoạt hình nổi trên màn hình: đi, leo tường, tùy chỉnh, dùng app khác.",
    shortDescriptionEn:
      "A floating animated buddy on your screen: walk, climb, customize, keep using other apps.",
    content: itemPlainTextVi({ play, android, windows, version }),
    contentEn: itemPlainTextEn({ play, android, windows, version }),
    thumbnail: THUMB,
    downloadUrl: play || android || windows,
    images: [THUMB],
    tags: [TAG, "android", "windows", "overlay", "goddie9x"],
    sectionIds,
    order: 0,
    isHidden: false,
  };
}

export function samePublicFields(current, next) {
  return (
    (current.shortDescription || "") === next.shortDescription &&
    (current.shortDescriptionEn || "") === (next.shortDescriptionEn || "") &&
    (current.content || "") === next.content &&
    (current.contentEn || "") === (next.contentEn || "") &&
    (current.titleEn || "") === (next.titleEn || "") &&
    (current.downloadUrl || "") === next.downloadUrl &&
    (current.thumbnail || "") === next.thumbnail
  );
}

function itemPlainTextVi({ play, android, windows, version }) {
  return [
    "🚀 T Screen Funny Animation – buddy hoạt hình sống trên màn hình",
    "",
    "Nhân vật (buddy) đi, đứng idle, rơi và leo theo cạnh màn hình trong khi bạn vẫn mở app khác. Overlay là cửa sổ nhỏ bám theo buddy: chạm để kéo; chạm ra ngoài dùng máy bình thường. Thương hiệu T · goddie9x, miễn phí.",
    "",
    "## Tính năng",
    "",
    "• Buddy nổi trên các ứng dụng khác (Android overlay / Windows desktop)",
    "• Đi, leo tường, rơi, đứng nghỉ — kéo thả bằng tay",
    "• Tùy chỉnh tốc độ, kích thước, số lượng; giao diện sáng/tối; VI / EN",
    "• Tạo nhân vật riêng: gắn ảnh đầu, thân, tay, chân từ thư viện",
    "",
    "## Quyền Android (chỉ để hiện overlay)",
    "",
    "• Hiển thị trên ứng dụng khác — vẽ buddy phía trên app khác",
    "• Dịch vụ foreground specialUse — giữ overlay khi app xuống nền (có thông báo hệ thống)",
    "• Thông báo — thông báo đi kèm overlay, không phải marketing",
    "",
    "Không thu thập dữ liệu cá nhân, không quảng cáo. Chính sách quyền riêng tư:",
    PRIVACY,
    "",
    `## Tải bản ${version}`,
    "",
    play ? `• Google Play → ${play}` : "• Google Play → đang duyệt / nội bộ",
    android ? `• Android App Bundle (GitHub Release) → ${android}` : "• Android AAB → đang đóng gói",
    windows ? `• Windows x64 zip → ${windows}` : "• Windows x64 → đang đóng gói",
    "",
    "Trên Android: mở app → cấp quyền overlay → bấm “Hiện buddy ngoài màn hình”.",
  ].join("\n");
}

function itemPlainTextEn({ play, android, windows, version }) {
  return [
    "🚀 T Screen Funny Animation – a buddy that lives on your screen",
    "",
    "An animated character walks, idles, falls, and climbs screen edges while you use other apps. The overlay is a small window that follows the buddy: drag it; taps outside go to your apps. Brand T · goddie9x, free.",
    "",
    "## Features",
    "",
    "• Buddy over other apps (Android overlay / Windows desktop)",
    "• Walk, climb, fall, idle — drag with your finger or mouse",
    "• Speed, size, count; light/dark; Vietnamese / English",
    "• Custom presets: attach your own head/body/arm/leg images",
    "",
    "## Android permissions (overlay only)",
    "",
    "• Display over other apps — draw the buddy above other apps",
    "• Foreground service specialUse — keep the overlay after leaving the UI (with a system notification)",
    "• Notifications — ongoing overlay notice, not marketing",
    "",
    "No personal data collection, no ads. Privacy policy:",
    PRIVACY,
    "",
    `## Download ${version}`,
    "",
    play ? `• Google Play → ${play}` : "• Google Play → under review / internal",
    android ? `• Android App Bundle (GitHub Release) → ${android}` : "• Android AAB → packaging",
    windows ? `• Windows x64 zip → ${windows}` : "• Windows x64 → packaging",
    "",
    "On Android: open the app → grant overlay permission → tap “Show buddy on screen”.",
  ].join("\n");
}
