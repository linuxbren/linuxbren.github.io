// X traffic for the logbook. Newest first.
// Replace the sample entries with real posts: paste the text and the status URL.
//   kind: "post" | "reply"      to: handle you replied to (replies only)
//   at:   ISO time (UTC)        url: https://x.com/rookios72/status/<id>
// Entries with sample:true render with a SAMPLE stamp. Delete that flag for real ones.
window.X_HANDLE = "rookios72";
window.X_POSTS = [
  { kind: "post",  at: "2026-09-24T14:20:00Z", text: "Sample post: tidefiles is up. Three panes, inline image previews, follows your Omarchy theme.", url: "https://x.com/rookios72", sample: true },
  { kind: "reply", at: "2026-09-22T19:05:00Z", to: "someone", text: "Sample reply: yes, it reads your live theme colors, so the scope always matches.", url: "https://x.com/rookios72", sample: true },
  { kind: "post",  at: "2026-09-22T13:30:00Z", text: "Sample post: flyover 0.2.0 is out. The radar scope now runs as a native Omarchy screensaver.", url: "https://x.com/rookios72", sample: true },
  { kind: "post",  at: "2026-09-16T07:00:00Z", text: "Sample post: flyover-pill puts an aircraft count in the Omarchy bar. Click it for the scope.", url: "https://x.com/rookios72", sample: true }
];
